package main

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"encoding/gob"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

func server_check(e error) {
	if e != nil {
		f, err := os.OpenFile("/tmp/server.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return
		}
		defer f.Close()
		fmt.Fprintf(f, "FATAL: %s\n", e)
		os.Exit(1)
	}
}

func server_log(format string, args ...interface{}) {
	if debugOn {
		f, err := os.OpenFile("/tmp/server.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return
		}
		defer f.Close()
		fmt.Fprintf(f, "DEBUG: "+format+"\n", args...)
	}
}

func postMessage(serverEncoder *gob.Encoder, request interface{}) {
	server_log("sending request %s", toString(request))
	err := serverEncoder.Encode(&request)
	server_check(err)
}

func runServer() {
	if debugOn {
		os.Remove("/tmp/server.log")
	}

	server_log("sending BuildID = %s", BuildID)
	fmt.Println(BuildID)

	serverOut := bufio.NewWriter(os.Stdout)
	serverEncoder := gob.NewEncoder(serverOut)

	d := gob.NewDecoder(os.Stdin)
	done := false
	for !done {
		var msg interface{}
		err := d.Decode(&msg)
		server_check(err)
		server_log("received msg %s", toString(msg))

		switch msg := msg.(type) {
		case scanMsg:
			handleScanMsg(msg, serverEncoder)
			serverOut.Flush()
		case fileMsg:
			handleFileMsg(msg)
			serverOut.Flush()
		case doneFileMsg:
			handleDoneFileMsg(serverEncoder, serverOut)
			done = true
		default:
			server_log("unexpected msg: %T%v", msg)
			done = true
		}
	}
	os.Stdin.Close()
	os.Stdout.Close()
	os.Stderr.Close()
}
func handleScanMsg(scans scanMsg, serverOut *gob.Encoder) {

	request := make(requestMsg, 0, len(scans))
	lastSyncs := make(map[string]lastSyncData)

	for _, scan := range scans {
		lastSyncData, ok := lastSyncs[scan.Dst]
		if ok {
			continue
		}
		server_log("reading lastsync for %s", scan.Dst)
		lastSyncData = readLastSync(scan.Dst)

		relpaths := make([]string, 0, len(scan.Scan))
		for _, l := range scan.Scan {

			var timestamp int64
			var relpath, ln, gitRevision string

			switch l := l.(type) {
			case fileToSync:
				relpath = l.Relpath
				timestamp = l.T
			case revToSync:
				relpath = l.Relpath
				gitRevision = l.Revision
			case symLinkToSync:
				relpath = l.Relpath
				timestamp = l.T
				ln = l.Target
			}
			if len(relpath) == 0 {
				continue
			}

			if len(gitRevision) > 0 {
				dstDir := path.Join(scan.Dst, relpath)
				os.MkdirAll(dstDir, 0755)
				os.WriteFile(path.Join(dstDir, ".gitrevision"),
					[]byte(gitRevision+"\n"), 0644)
			} else {
				// add to the list of files being sync
				lastSyncData.syncFiles[relpath] = true
				// remove from list of files that were last sync
				delete(lastSyncData.lastSyncFiles, relpath)

				if timestamp > lastSyncData.lastSyncTime {
					dstFile := path.Join(scan.Dst, relpath)
					dstDir := path.Dir(dstFile)
					os.MkdirAll(dstDir, 0755)

					if len(ln) > 0 {
						// it's a symlink
						if runtime.GOOS == "windows" {
							// that's what git does on windows...
							os.WriteFile(dstFile, []byte(ln+"\n"), 0644)
						} else {
							os.Symlink(ln, dstFile)
						}
					} else {
						server_log("adding %s, %d > %d", relpath, timestamp, lastSyncData.lastSyncTime)
						relpaths = append(relpaths, relpath)
					}
				}
				if timestamp > lastSyncData.latest {
					lastSyncData.latest = timestamp
				}
			}
		}
		lastSyncs[scan.Dst] = lastSyncData
		request = append(request, requestData{scan.Dst, relpaths})
	}
	postMessage(serverOut, request)

	for _, scan := range scans {
		lastSyncData, ok := lastSyncs[scan.Dst]
		if !ok {
			continue
		}
		// anything left in lastSyncFiles should be deleted
		foldersToPrune := make(map[string]bool)
		for k := range lastSyncData.lastSyncFiles {
			p := path.Join(scan.Dst, k)
			server_log("deleting %s", p)
			os.Remove(p)
			foldersToPrune[path.Dir(p)] = true
		}
		pruneEmptyFolders(scan.Dst, foldersToPrune)

		// write the new .lastsync
		file, err := os.Create(path.Join(scan.Dst, ".lastsync"))
		server_check(err)
		defer file.Close()
		w := bufio.NewWriter(file)
		defer w.Flush()

		// lastest sync time
		fmt.Fprintf(w, "%d\n", lastSyncData.latest)

		// all files
		for k := range lastSyncData.syncFiles {
			fmt.Fprintln(w, k)
		}
	}
}
func handleDoneFileMsg(serverEncoder *gob.Encoder, serverOut *bufio.Writer) {

	postMessage(serverEncoder, doneSync{})
	serverOut.Flush()
}

type lastSyncData struct {
	lastSyncTime  int64
	lastSyncFiles map[string]bool
	latest        int64
	syncFiles     map[string]bool
}

func readLastSync(dst string) lastSyncData {

	// read .lastsync, first line is the last sync timestamp
	// followed by all files that were sync
	lastSyncFiles := make(map[string]bool)
	server_log("readind %s/.lastsync", dst)
	file, err := os.Open(path.Join(dst, ".lastsync"))
	if err != nil {
		return lastSyncData{0, map[string]bool{}, 0, map[string]bool{}}
	}
	defer file.Close()
	lines := bufio.NewScanner(file)
	if !lines.Scan() {
		return lastSyncData{0, map[string]bool{}, 0, map[string]bool{}}
	}
	lastSyncTime, _ := strconv.ParseInt(lines.Text(), 10, 64)
	for lines.Scan() {
		lastSyncFiles[lines.Text()] = true
	}

	return lastSyncData{lastSyncTime, lastSyncFiles, 0, map[string]bool{}}
}

func handleFileMsg(file fileMsg) {
	fullPath := path.Join(file.Dst, file.Relpath)
	var fm fs.FileMode = 0644
	if file.IsExe {
		fm = 0755
	}
	server_log("writing file %s isExe %t", file.Relpath, file.IsExe)
	if file.IsCompressed {
		WriteFileCompressed(fullPath, file.Data, fm)
	} else {
		os.WriteFile(fullPath, file.Data, fm)
	}
	os.Chmod(fullPath, fm)
}
func WriteFileCompressed(path string, data []byte, mode fs.FileMode) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	file.Chmod(mode)

	z, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return err
	}
	defer z.Close()
	_, err = io.Copy(file, z)
	return err
}
func pruneEmptyFolders(dst string, foldersToPrune map[string]bool) {
	if foldersToPrune == nil {
		// foldersToPrune is not defined, find ALL the leaf folders
		foldersToPrune = make(map[string]bool)
		filepath.Walk(dst, func(current string, info os.FileInfo, err error) error {
			if info.IsDir() {
				for p := range foldersToPrune {
					if strings.HasPrefix(current, p) {
						delete(foldersToPrune, p)
					}
				}
				foldersToPrune[current] = true
			}
			return nil
		})
	}
	for p := range foldersToPrune {
		for p != dst {
			if !folderShouldBeRemoved(p) {
				break
			}
			os.RemoveAll(p)
			p = path.Dir(p)
		}
	}
}
func folderShouldBeRemoved(p string) bool {
	f, err := os.Open(p)
	if err != nil {
		return false
	}
	defer f.Close()
	entries, _ := f.Readdir(2)
	if len(entries) == 0 {
		return true
	}
	return len(entries) == 1 && entries[0].Name() == ".gitrevision"
}
