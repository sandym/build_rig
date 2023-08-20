package main

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"encoding/gob"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"sync"
)

func client_check(e error) {
	if e != nil {
		log.Fatalf("%s", e)
	}
}
func client_log(format string, args ...interface{}) {
	if debugOn {
		fmt.Fprintf(os.Stderr, "DEBUG: "+format+"\n", args...)
		os.Stderr.Sync()
	}
}

type serverDef struct {
	cmd *exec.Cmd
	// output from server
	stdout  io.ReadCloser
	rcv     *bufio.Reader
	decoder *gob.Decoder
	// input to server
	stdin   io.WriteCloser
	snd     *bufio.Writer
	encoder *gob.Encoder
}

func runClient(configOption string) {
	config := readConfig(configOption)

	for _, folder := range config.Folders {
		if !isDirectory(folder.Src) {
			log.Fatalf("%s is not a directory", folder.Src)
		}
		fmt.Printf("--> scanning %s\n", folder.Src)
	}

	allDone := make(chan int)
	scans := fillScans(config.Folders, allDone)

	serverDef := startServer(config)
	for {
		_, more := <-allDone
		if !more {
			break
		}
	}

	allDone = make(chan int)
	msgQueue := make(chan interface{})

	go serviceServerRequests(config, serverDef, msgQueue)
	go serviceMsgQueue(serverDef, msgQueue, allDone)
	msgQueue <- scans

	client_log("waiting for allDone")
	for {
		_, more := <-allDone
		if !more {
			break
		}
	}

	serverDef.stdin.Close()

	var wg sync.WaitGroup
	wg.Add(1)

	go func() {
		buf := make([]byte, 1024)
		for {
			n, err := serverDef.stdout.Read(buf[:])
			if n > 0 {
				d := buf[:n]
				_, err := os.Stdout.Write(d)
				if err != nil {
					break
				}
			}
			if err != nil {
				break
			}
		}
		wg.Done()
	}()
	wg.Wait()
	serverDef.cmd.Wait()

	client_log("done")
}

func fillScans(folders []FolderToCopy, allDone chan int) scanMsg {

	scans := make(scanMsg, 0, len(folders))

	for _, folder := range folders {
		scan := make([]interface{}, 0, 256)
		counter := make(chan int)
		output := make(chan interface{})
		scanInProgress := 1
		done := false
		go scanFolder(folder.Src, folder.Src, output, counter)
		for !done {
			select {
			case s, more := <-output:
				if more {
					scan = append(scan, s)
				} else {
					scans = append(scans, scanFolderData{folder.Dst, scan})
					done = true
				}
			case c := <-counter:
				scanInProgress += c
				if scanInProgress == 0 {
					close(output)
				}
			}
		}
	}
	close(allDone)
	return scans
}
func scanFolder(srcFullPath, currentPath string, output chan<- interface{}, counter chan<- int) {
	defer func() {
		counter <- -1
	}()

	dirp, err := os.Open(currentPath)
	if err != nil {
		return
	}
	entries, err := dirp.Readdir(-1)
	dirp.Close()
	if err != nil {
		return
	}

	for _, finfo := range entries {
		if finfo.Name() == ".git" {
			// record git revision
			result := gitRevision(currentPath)
			if len(result) > 0 {
				relpath, err := filepath.Rel(srcFullPath, currentPath)
				if err == nil {
					relpath = strings.ReplaceAll(relpath, "\\", "/")
					output <- revToSync{relpath, result}
				}
			}
			continue
		}

		// skip those
		if shouldSkip(finfo.Name()) {
			continue
		}

		fullPath := path.Join(currentPath, finfo.Name())

		switch {
		case finfo.Mode().IsRegular():
			relpath, err := filepath.Rel(srcFullPath, fullPath)
			if err == nil {
				relpath = strings.ReplaceAll(relpath, "\\", "/")
				output <- fileToSync{relpath, finfo.ModTime().Unix()}
			}
		case finfo.Mode().IsDir():
			counter <- 1
			go scanFolder(srcFullPath, fullPath, output, counter)
		case (finfo.Mode() & os.ModeSymlink) != 0:
			ln, err := os.Readlink(fullPath)
			if err == nil {
				relpath, err := filepath.Rel(srcFullPath, fullPath)
				if err == nil {
					relpath = strings.ReplaceAll(relpath, "\\", "/")
					output <- symLinkToSync{relpath, finfo.ModTime().Unix(), ln}
				}
			}
		}
	}
}
func gitRevision(wd string) string {
	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Dir = wd
	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	err := cmd.Run()
	if err == nil {
		lines := strings.Split(stdout.String(), "\n")
		if len(lines) > 0 {
			return lines[0]
		}
	}
	return ""
}
func shouldSkip(name string) bool {
	return name == ".DS_Store" ||
		name == ".editorconfig" ||
		name == ".clang-format" ||
		name == ".vscode" ||
		name == ".vs" ||
		name == "Cargo.lock" ||
		name == "node_modules" ||
		strings.HasPrefix(name, ".git")
}

func startServer(config config) serverDef {

	fmt.Printf("--> starting server\n")

	args := make([]string, 0, len(config.TransportCmd)+4)
	args = append(args, config.TransportCmd...)
	args = append(args, config.RemotePath)
	if debugOn {
		args = append(args, "-debug")
	}

	var cmd *exec.Cmd
	var rcv *bufio.Reader
	var snd *bufio.Writer
	var stdin io.WriteCloser
	var stdout io.ReadCloser
	for i := 0; i < 2; i++ {
		cmd = exec.Command(args[0], args[1:]...)
		cmd.Stderr = os.Stderr
		stdout, _ = cmd.StdoutPipe()
		var err error
		stdin, err = cmd.StdinPipe()
		client_check(err)
		rcv = bufio.NewReader(stdout)
		snd = bufio.NewWriter(stdin)

		err = cmd.Start()
		if err == nil {

			client_log("server start succeeded")

			// check BuildID
			var p []byte
			p, _, err = rcv.ReadLine()
			if err == nil {
				serverBuildID := strings.TrimSpace(string(p))
				if serverBuildID == BuildID {
					client_log("BuildIDs are equal")
					break
				}
				client_log("BuildID is different '%s' != '%s'", BuildID, serverBuildID)
				cmd.Process.Kill()
				err = fmt.Errorf("BuildID: expecting '%s' got '%s'", BuildID, serverBuildID)
			}
		}
		if i == 0 {
			fmt.Printf("--> copying server to remote\n")
			copyArgs := make([]string, 0, len(config.CopyCmd)+1)
			copyArgs = append(copyArgs, config.CopyCmd...)
			cp := exec.Command(copyArgs[0], copyArgs[1:]...)
			cp.Run()
		} else {
			client_check(err)
		}
	}

	serverDef := serverDef{cmd, stdout, rcv, gob.NewDecoder(rcv), stdin, snd, gob.NewEncoder(snd)}
	return serverDef
}
func serviceServerRequests(config config, serverDef serverDef, msgQueue chan interface{}) {
	done := false
	for !done {
		var request interface{}
		err := serverDef.decoder.Decode(&request)
		client_check(err)

		switch request := request.(type) {
		case requestMsg:
			client_log("received request %s", toString(request))
			go handleRequestMsg(config, msgQueue, request)
		case buildStartingMsg:
			fmt.Printf("--> starting build\n")
			done = true
		default:
			client_log("unexpected request: %v", request)
			done = true
		}
	}
	close(msgQueue)
}
func handleRequestMsg(config config, msgQueue chan<- interface{}, requests requestMsg) {

	nbOfFileToUpdate := 0
	for _, request := range requests {
		nbOfFileToUpdate += len(request.Relpaths)
	}
	if nbOfFileToUpdate == 0 {
		fmt.Printf("--> all files up-to-date\n")
	} else {
		fmt.Printf("--> sync'ing files\n")
	}

	for _, request := range requests {

		if len(request.Relpaths) == 0 {
			continue
		}

		compressFiles := config.CompressFiles
		maxOutput := 10
		for i, relpath := range request.Relpaths {
			if i > maxOutput {
				fmt.Printf("+ %d more files\n", len(request.Relpaths)-maxOutput)
				break
			}
			fmt.Println(relpath)
		}
		for _, relpath := range request.Relpaths {
			srcFullPath := path.Join(config.srcForDst(request.Dst), relpath)
			finfo, err := os.Stat(srcFullPath)
			client_check(err)
			isExe := isExecutable(srcFullPath, finfo)

			var data []byte
			if compressFiles {
				data, err = readFileCompressed(srcFullPath)
				client_check(err)
			} else {
				data, err = os.ReadFile(srcFullPath)
				client_check(err)
			}
			msgQueue <- fileMsg{request.Dst, relpath, isExe, compressFiles, data}
		}
	}
	msgQueue <- buildCmdMsg{config.BuildCmd}
}
func readFileCompressed(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var b bytes.Buffer
	z, err := gzip.NewWriterLevel(&b, gzip.BestSpeed)
	if err != nil {
		return nil, err
	}
	defer z.Close()

	_, err = io.Copy(z, file)
	if err != nil {
		return nil, err
	}
	err = z.Close()
	if err != nil {
		return nil, err
	}
	return b.Bytes(), nil
}
func serviceMsgQueue(serverDef serverDef, msgQueue <-chan interface{}, allDone chan<- int) {
	for {
		msg, more := <-msgQueue
		if !more {
			break
		}
		client_log("sending msg %s", toString(msg))
		err := serverDef.encoder.Encode(&msg)
		client_check(err)
		serverDef.snd.Flush()
	}
	close(allDone)
}
