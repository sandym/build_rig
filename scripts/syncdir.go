// - scan: -scan {path}...
// - sync: -sync {src} {dst}...
// - clean: -clean {path}...
// - headers: -headers {dst} {paths}...

package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

func main() {
	scanPtr := flag.Bool("scan", false, "-scan {path}...")
	syncPtr := flag.Bool("sync", false, "-sync {src} {dst}...")
	cleanPtr := flag.Bool("clean", false, "-clean {dst}")
	headersPtr := flag.Bool("headers", false, "-headers {dst} {paths}...")
	flag.Parse()

	switch {
	case *scanPtr && flag.NArg() >= 1:
		for _, path := range flag.Args() {
			updateScan(path)
		}
	case *syncPtr && (flag.NArg()&1) == 0:
		for i := 0; i < flag.NArg(); i += 2 {
			syncFolders(flag.Args()[i], flag.Args()[i+1])
		}
	case *cleanPtr && flag.NArg() >= 1:
		for _, path := range flag.Args() {
			cleanFolder(path)
		}
	case *headersPtr && len(flag.Args()) >= 2:
		buildHeaders(flag.Args()[0], flag.Args()[1:])
	default:
		flag.PrintDefaults()
	}
}
func gitRevision(wd string) string {
	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Dir = wd
	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	err := cmd.Run()
	if err == nil {
		lines := strings.Split(string(stdout.Bytes()), "\n")
		if len(lines) > 0 {
			return lines[0]
		}
	}
	return ""
}
func isExecutable(fullpath string, finfo os.FileInfo) bool {
	if runtime.GOOS == "windows" {
		// cannot find how to get the mingw x file permission on windows,
		// just fake it...
		ext := path.Ext(fullpath)
		if ext == ".sh" {
			return true
		}
		name := path.Base(fullpath)
		if name == "configure" {
			return true
		}
	}
	return (finfo.Mode() & 0111) != 0
}
func scanFolder(srcFullPath, currentPath string, output chan string, counter chan int) {
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
					output <- fmt.Sprintf("s %s %s\n", result, relpath)
				}
			}
			continue
		}

		// skip those
		if finfo.Name() == ".tosync" ||
			finfo.Name() == ".vscode" ||
			finfo.Name() == "node_modules" ||
			strings.HasPrefix(finfo.Name(), ".git") {
			continue
		}

		fullPath := path.Join(currentPath, finfo.Name())

		switch {
		case finfo.Mode().IsRegular():
			relpath, err := filepath.Rel(srcFullPath, fullPath)
			if err == nil {
				relpath = strings.ReplaceAll(relpath, "\\", "/")
				if isExecutable(fullPath, finfo) {
					output <- fmt.Sprintf("x %d %s\n", finfo.ModTime().Unix(), relpath)
				} else {
					output <- fmt.Sprintf("f %d %s\n", finfo.ModTime().Unix(), relpath)
				}
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
					output <- fmt.Sprintf("l %d %s->%s\n", finfo.ModTime().Unix(), relpath, ln)
				}
			}
		}
	}
}
func updateScan(srcFullPath string) {
	if !isDirectory(srcFullPath) {
		log.Fatalf("%s is not a directory", srcFullPath)
	}
	fmt.Printf("🔄 scanning %s...\n", srcFullPath)

	file, err := os.Create(path.Join(srcFullPath, ".tosync"))
	check(err)
	defer file.Close()
	w := bufio.NewWriter(file)
	defer w.Flush()

	counter := make(chan int)
	output := make(chan string)
	scanInProgress := 1
	go scanFolder(srcFullPath, srcFullPath, output, counter)
	for {
		select {
		case s, more := <-output:
			if more {
				w.WriteString(s)
			} else {
				return
			}
		case c := <-counter:
			scanInProgress += c
			if scanInProgress == 0 {
				close(output)
			}
		}
	}
}
func readLastSync(dst string) (lastSync int64, lastSyncFiles map[string]bool) {
	// read .lastsync, first line is the last sync timestamp
	// followed by all files that were sync
	lastSyncFiles = make(map[string]bool)
	file, err := os.Open(path.Join(dst, ".lastsync"))
	if err != nil {
		return lastSync, lastSyncFiles
	}
	defer file.Close()
	lines := bufio.NewScanner(file)
	if !lines.Scan() {
		return lastSync, lastSyncFiles
	}
	lastSync, _ = strconv.ParseInt(lines.Text(), 10, 64)
	for lines.Scan() {
		lastSyncFiles[lines.Text()] = true
	}

	return lastSync, lastSyncFiles
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
			fmt.Printf("deleting %s\n", p)
			os.RemoveAll(p)
			p = path.Dir(p)
		}
	}
}
func splitAtFirstSpace(v string) []string {
	idx := strings.IndexRune(v, ' ')
	if idx < 1 {
		return []string{}
	}
	return []string{v[:idx], v[idx+1:]}
}
func splitLink(v string) []string {
	idx1 := strings.IndexRune(v, ' ')
	if idx1 < 1 {
		return []string{}
	}
	idx2 := strings.Index(v, "->")
	if idx2 < (idx1 + 2) {
		return []string{}
	}

	return []string{v[:idx1], v[idx1+1 : idx2], v[idx2+2:]}
}
func syncFolders(src, dst string) {
	if !isDirectory(src) {
		log.Fatalf("%s is not a directory", src)
	}
	fmt.Printf("🔄 sync'ing %s to %s\n", src, dst)

	lastSync, lastSyncFiles := readLastSync(dst)

	// read .tosync
	//   one timestamp and one file per line
	toSync, err := os.Open(path.Join(src, ".tosync"))
	check(err)
	defer toSync.Close()
	lines := bufio.NewScanner(toSync)

	var latest int64
	syncFiles := make(map[string]bool)
	for lines.Scan() {
		line := lines.Text()

		var timestamp int64
		var relpath, ln, gitRevision string
		isExe := fileIsNotExe

		prefix := line[:2]
		line = line[2:]
		switch prefix {
		case "x ":
			isExe = fileIsExe
			fallthrough
		case "f ":
			// parse the line: "timestamp relative-path"
			comps := splitAtFirstSpace(line)
			if len(comps) == 2 {
				timestamp, _ = strconv.ParseInt(comps[0], 10, 64)
				relpath = comps[1]
			}
		case "s ":
			// parse the line: "git-revision relative-path"
			comps := splitAtFirstSpace(line)
			if len(comps) == 2 {
				gitRevision = comps[0]
				relpath = comps[1]
			}
		case "l ":
			// parse the line: "timestamp relative-path->link"
			matches := splitLink(line)
			if len(matches) == 3 {
				timestamp, _ = strconv.ParseInt(matches[0], 10, 64)
				relpath = matches[1]
				ln = matches[2]
			}
		}
		if len(relpath) == 0 {
			continue
		}

		if len(gitRevision) > 0 {
			dstDir := path.Join(dst, relpath)
			os.MkdirAll(dstDir, 0755)
			ioutil.WriteFile(path.Join(dstDir, ".gitrevision"),
				[]byte(gitRevision+"\n"), 0644)
		} else {
			// add to the list of files being sync
			syncFiles[relpath] = true
			// remove from list of files that were last sync
			delete(lastSyncFiles, relpath)

			if timestamp > lastSync {
				srcFile := path.Join(src, relpath)
				dstFile := path.Join(dst, relpath)
				dstDir := path.Dir(dstFile)
				os.MkdirAll(dstDir, 0755)

				// don't output every single file if it's a full sync
				// makes it a bit faster
				if lastSync > 0 {
					fmt.Println(relpath)
				}
				if len(ln) > 0 {
					// it's a symlink
					if runtime.GOOS == "windows" {
						// that's what git does on windows...
						ioutil.WriteFile(path.Join(dstDir, path.Base(srcFile)),
							[]byte(ln+"\n"), 0644)
					} else {
						os.Symlink(ln, path.Join(dstDir, path.Base(srcFile)))
					}
				} else {
					copyFile(srcFile, dstFile, isExe)
				}
			}
			if timestamp > latest {
				latest = timestamp
			}
		}
	}

	// anything left in lastSyncFiles should be deleted
	foldersToPrune := make(map[string]bool)
	for k := range lastSyncFiles {
		p := path.Join(dst, k)
		fmt.Printf("deleting %s\n", p)
		os.Remove(p)
		foldersToPrune[path.Dir(p)] = true
	}
	pruneEmptyFolders(dst, foldersToPrune)

	// write the new .lastsync
	file, err := os.Create(path.Join(dst, ".lastsync"))
	check(err)
	defer file.Close()
	w := bufio.NewWriter(file)
	defer w.Flush()

	// lastest sync time
	fmt.Fprintf(w, "%d\n", latest)

	// all files
	for k := range syncFiles {
		fmt.Fprintln(w, k)
	}
}
func cleanFolder(dst string) {
	if !isDirectory(dst) {
		return
	}
	fmt.Printf("🗑 cleaning %s\n", dst)

	_, lastSyncFiles := readLastSync(dst)

	stack := make([]string, 0, 64)
	stack = append(stack, dst)
	for len(stack) > 0 {
		n := len(stack)
		f := stack[n-1]
		stack = stack[:n-1]
		files, err := ioutil.ReadDir(f)
		check(err)
		for _, finfo := range files {
			if finfo.Name() == ".lastsync" || finfo.Name() == ".gitrevision" {
				continue
			}
			srcpath := path.Join(f, finfo.Name())
			if finfo.IsDir() {
				stack = append(stack, srcpath)
			} else {
				relpath := srcpath[len(dst)+1:]
				if _, ok := lastSyncFiles[relpath]; !ok {
					p := path.Join(dst, relpath)
					fmt.Printf("deleting %s\n", p)
					os.Remove(p)
				}
			}
		}
	}
	pruneEmptyFolders(dst, nil)
}
func folderShouldBeRemoved(p string) bool {
	f, err := os.Open(p)
	if err != nil {
		return false
	}
	defer f.Close()
	entries, _ := f.Readdir(2)
	if len(entries) == 1 {
		return entries[0].Name() == ".gitrevision"
	}
	return len(entries) == 0
}
func isDirectory(path string) bool {
	fileInfo, err := os.Stat(path)
	return err == nil && fileInfo.IsDir()
}
func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

type isFileExe int

const (
	fileIsNotExe isFileExe = 0
	fileIsExe    isFileExe = 1
	dontKnow     isFileExe = 2
)

func copyFile(src, dst string, isExe isFileExe) {
	source, err := os.Open(src)
	check(err)
	defer source.Close()

	destination, err := os.Create(dst)
	check(err)
	defer destination.Close()
	_, err = io.Copy(destination, source)
	check(err)
	// restore execution bit
	switch isExe {
	case fileIsExe:
		sourceFileStat, err := os.Stat(src)
		if err == nil {
			os.Chmod(dst, sourceFileStat.Mode()&os.ModePerm|0111)
		}
	case dontKnow:
		sourceFileStat, err := os.Stat(src)
		if err != nil {
			return
		}
		if !sourceFileStat.Mode().IsRegular() {
			return
		}
		if (sourceFileStat.Mode() & 0111) != 0 {
			os.Chmod(dst, sourceFileStat.Mode()&os.ModePerm|0111)
		}
	default:
	}
}
func buildHeaders(dst string, folders []string) {
	err := os.RemoveAll(dst)
	check(err)
	err = os.MkdirAll(dst, 0755)
	check(err)

	for _, folder := range folders {
		fmt.Println(folder)

		stack := make([]string, 0, 64)
		stack = append(stack, folder)
		for len(stack) > 0 {
			n := len(stack)
			p := stack[n-1]
			stack = stack[:n-1]
			files, err := ioutil.ReadDir(p)
			check(err)
			for _, finfo := range files {
				name := finfo.Name()
				srcpath := path.Join(p, name)
				switch {
				case finfo.IsDir():
					if name == "bin" || name == "share" || name == "lib" {
						continue
					}
					stack = append(stack, srcpath)
				case (finfo.Mode() & os.ModeSymlink) != 0:
					ln, err := os.Readlink(srcpath)
					check(err)
					err = os.MkdirAll(path.Join(dst, p), 0755)
					check(err)
					if !path.IsAbs(ln) {
						os.Symlink(ln, path.Join(dst, srcpath))
					}
				default:
					ext := path.Ext(name)
					if ext == "" ||
						ext == ".h" ||
						ext == ".cc" ||
						ext == ".c" ||
						ext == ".cpp" ||
						ext == ".hpp" ||
						ext == ".ipp" ||
						ext == ".tcc" ||
						ext == ".inc" ||
						ext == ".inl" {
						err = os.MkdirAll(path.Join(dst, p), 0755)
						check(err)
						copyFile(srcpath, path.Join(dst, srcpath), dontKnow)
					}
				}
			}
		}
	}
}
