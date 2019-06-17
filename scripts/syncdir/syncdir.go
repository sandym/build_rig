// - scan: -scan {path}...
// - sync: -sync {src} {dst}...
// - clean: -clean {path}...
// - backsync: -backsync {dst} {src}
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
	"regexp"
	"runtime"
	"strconv"
	"strings"
)

func main() {
	scanPtr := flag.Bool("scan", false, "-scan {path}...")
	syncPtr := flag.Bool("sync", false, "-sync {src} {dst}...")
	cleanPtr := flag.Bool("clean", false, "-clean {dst}")
	backsyncPtr := flag.Bool("backsync", false, "-backsync {dst} {src}")
	headersPtr := flag.Bool("headers", false, "-headers {dst} {paths}...")
	flag.Parse()

	switch {
	case *scanPtr && len(flag.Args()) >= 1:
		for _, path := range flag.Args() {
			updateScan(path)
		}
	case *syncPtr && (len(flag.Args())&1) == 0:
		for i := 0; i < len(flag.Args()); i += 2 {
			syncFolders(flag.Args()[i], flag.Args()[i+1])
		}
	case *cleanPtr && len(flag.Args()) >= 1:
		for _, path := range flag.Args() {
			cleanFolder(path)
		}
	case *backsyncPtr && len(flag.Args()) == 2:
		backsyncFolders(flag.Args()[0], flag.Args()[1])
	case *headersPtr && len(flag.Args()) >= 2:
		buildHeaders(flag.Args()[0], flag.Args()[1:])
	default:
		// take a guess
		switch {
		case len(flag.Args()) == 1:
			updateScan(flag.Args()[0])
		case len(flag.Args()) == 2:
			syncFolders(flag.Args()[0], flag.Args()[1])
		default:
			flag.PrintDefaults()
		}
	}
}
func captureLines(cmd *exec.Cmd, wd string) []string {
	cmd.Dir = wd
	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	err := cmd.Run()
	if err == nil {
		return strings.Split(string(stdout.Bytes()), "\n")
	}
	return make([]string, 0, 0)
}
func gitListAllFiles(src string) []string {
	result := captureLines(exec.Command("git", "ls-files"), src)
	return append(result, captureLines(exec.Command("git", "ls-files", "--others", "--exclude-standard"), src)...)
}
func updateScan(src string) {
	if !isDirectory(src) {
		log.Fatalf("%s is not a directory", src)
	}
	fmt.Printf("scanning %s\n", src)

	file, err := os.Create(path.Join(src, ".tosync"))
	check(err)
	defer file.Close()
	w := bufio.NewWriter(file)
	defer w.Flush()

	allFiles := gitListAllFiles(src)
	for len(allFiles) > 0 {
		n := len(allFiles)
		relpath := allFiles[n-1]
		allFiles = allFiles[:n-1]
		if len(relpath) == 0 ||
			relpath == ".tosync" ||
			strings.HasSuffix(relpath, ".DS_Store") ||
			strings.Contains(relpath, ".git") {
			continue
		}

		srcpath := path.Join(src, relpath)

		finfo, err := os.Lstat(srcpath)
		if err != nil {
			// probably a deleted file
			continue
		}
		if finfo.Mode().IsDir() {
			// probably a submodule, recurse
			otherFiles := gitListAllFiles(srcpath)
			for _, v := range otherFiles {
				if len(v) > 0 {
					allFiles = append(allFiles, path.Join(relpath, v))
				}
			}
		} else if finfo.Mode().IsRegular() || (finfo.Mode()&os.ModeSymlink) != 0 {
			fmt.Fprintf(w, "%d %s", finfo.ModTime().Unix(), relpath)

			if (finfo.Mode() & os.ModeSymlink) != 0 {
				ln, err := os.Readlink(srcpath)
				check(err)
				fmt.Fprintf(w, " -> %s", ln)
			}
			fmt.Fprintf(w, "\n")
		}
	}
}
func readLastSync(dst string) (lastSync int64, lastSyncFiles map[string]bool) {
	// read .lastsync
	//   first line is the last sync timestamp
	//   followed by all files that were sync
	file, err := os.Open(path.Join(dst, ".lastsync"))
	lastSyncFiles = make(map[string]bool)
	if err == nil {
		defer file.Close()
		lines := bufio.NewScanner(file)
		if lines.Scan() {
			lastSync, _ = strconv.ParseInt(lines.Text(), 10, 64)
			for lines.Scan() {
				lastSyncFiles[lines.Text()] = true
			}
		}
	}
	return lastSync, lastSyncFiles
}
func pruneEmptyFolders(dst string, foldersToPrune map[string]bool) {
	if foldersToPrune == nil {
		foldersToPrune = make(map[string]bool)
		filepath.Walk(dst, func(path string, info os.FileInfo, err error) error {
			if info.IsDir() {
				for p := range foldersToPrune {
					if strings.HasPrefix(path, p) {
						delete(foldersToPrune, p)
					}
				}
				foldersToPrune[path] = true
			}
			return nil
		})
	}
	for p := range foldersToPrune {
		for p != dst {
			if !isFolderEmpty(p) {
				break
			}
			fmt.Printf("deleting %s\n", p)
			os.Remove(p)
			p = path.Dir(p)
		}
	}
}
func syncFolders(src, dst string) {
	if !isDirectory(src) {
		log.Fatalf("%s is not a directory", src)
	}

	fmt.Printf("sync'ing %s to %s\n", src, dst)

	lastSync, lastSyncFiles := readLastSync(dst)

	// read .tosync
	//   one timestamp and one file per line
	toSync, err := os.Open(path.Join(src, ".tosync"))
	check(err)
	defer toSync.Close()
	lines := bufio.NewScanner(toSync)

	matchLinkRe := regexp.MustCompile("^(\\d+)\\s(.+)\\s\\->\\s(.+)$")
	matchFileRe := regexp.MustCompile("^(\\d+)\\s(.+)$")

	var latest int64
	syncFiles := make(map[string]bool)
	for lines.Scan() {
		line := lines.Text()

		var timestamp int64
		var relpath string
		var ln string

		matches := matchLinkRe.FindAllStringSubmatch(line, -1)
		if len(matches) == 1 {
			// parse the line: "timestamp relative-path -> link"
			timestamp, _ = strconv.ParseInt(matches[0][1], 10, 64)
			relpath = matches[0][2]
			ln = matches[0][3]
		} else {
			matches = matchFileRe.FindAllStringSubmatch(line, -1)
			if len(matches) == 1 {
				// parse the line: "timestamp relative-path"
				timestamp, _ = strconv.ParseInt(matches[0][1], 10, 64)
				relpath = matches[0][2]
			}
		}

		if timestamp == 0 || len(relpath) == 0 {
			continue
		}

		// add to the list of files being sync
		syncFiles[relpath] = true

		// remove from list of files that were last sync
		delete(lastSyncFiles, relpath)

		if timestamp > lastSync {
			srcFile := path.Join(src, relpath)
			dstFile := path.Join(dst, relpath)
			dstDirname := path.Dir(dstFile)
			os.MkdirAll(dstDirname, 0755)

			// don't output every single file if it's a full sync
			// makes it a bit faster
			if lastSync > 0 {
				fmt.Println(relpath)
			}
			if len(ln) > 0 {
				// it's a symlink
				if runtime.GOOS == "windows" {
					// that's what git does on windows...
					ioutil.WriteFile(path.Join(dstDirname, path.Base(srcFile)), []byte(ln), 0644)
				} else {
					os.Symlink(ln, path.Join(dstDirname, path.Base(srcFile)))
				}
			} else {
				copyFile(srcFile, dstFile)
			}
		}
		if timestamp > latest {
			latest = timestamp
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
	fmt.Fprintf(w, "%d\n", latest)
	for k := range syncFiles {
		fmt.Fprintf(w, "%s\n", k)
	}
}
func cleanFolder(dst string) {
	if !isDirectory(dst) {
		return
	}

	fmt.Printf("cleaning %s\n", dst)

	_, lastSyncFiles := readLastSync(dst)

	stack := make([]string, 0, 16)
	stack = append(stack, dst)
	for len(stack) > 0 {
		n := len(stack)
		f := stack[n-1]
		stack = stack[:n-1]
		files, err := ioutil.ReadDir(f)
		check(err)
		for _, finfo := range files {
			if finfo.Name() == ".lastsync" {
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
func isFolderEmpty(p string) bool {
	f, err := os.Open(p)
	if err != nil {
		return false
	}
	defer f.Close()
	_, err = f.Readdir(1)
	return err == io.EOF
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
func copyFile(src, dst string) {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return
	}
	if !sourceFileStat.Mode().IsRegular() {
		return
	}

	source, err := os.Open(src)
	check(err)
	defer source.Close()

	destination, err := os.Create(dst)
	check(err)
	defer destination.Close()
	_, err = io.Copy(destination, source)
	check(err)
	// restore execution bit
	if (sourceFileStat.Mode() & 0111) != 0 {
		os.Chmod(dst, sourceFileStat.Mode()&os.ModePerm|0111)
	}
}
func filesAreDifferent(file1, file2 string) bool {
	f1, err := os.Open(file1)
	if err != nil {
		return false
	}
	f2, err := os.Open(file2)
	if err != nil {
		return false
	}
	f1Info, err := f1.Stat()
	if err != nil {
		return false
	}
	f2Info, err := f2.Stat()
	if err != nil {
		return false
	}
	if f1Info.Size() != f2Info.Size() {
		return true
	}

	const chunkSize = 64 * 1024
	b1 := make([]byte, chunkSize)
	b2 := make([]byte, chunkSize)
	for {
		len1, err1 := f1.Read(b1)
		len2, err2 := f2.Read(b2)

		if err1 != nil || err2 != nil {
			if err1 == io.EOF && err2 == io.EOF {
				return false
			} else if err1 == io.EOF || err2 == io.EOF {
				return true
			} else {
				return false
			}
		}
		if len1 != len2 {
			return true
		}

		if !bytes.Equal(b1, b2) {
			return true
		}
	}
}
func backsyncFolders(dst, src string) {
	if !isDirectory(dst) {
		log.Fatalf("%s is not a directory", dst)
	}
	if !isDirectory(src) {
		log.Fatalf("%s is not a directory", src)
	}
	fmt.Printf("backsync'ing %s to %s\n", dst, src)

	_, lastSyncFiles := readLastSync(dst)
	for f := range lastSyncFiles {
		srcFile := path.Join(src, f)
		dstFile := path.Join(dst, f)
		if filesAreDifferent(srcFile, dstFile) {
			fmt.Println(f)
			copyFile(srcFile, dstFile)
		}
	}
}
func buildHeaders(dst string, folders []string) {
	err := os.RemoveAll(dst)
	check(err)
	err = os.MkdirAll(dst, 0755)
	check(err)

	for _, folder := range folders {
		fmt.Println(folder)

		stack := make([]string, 0, 16)
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
				if finfo.IsDir() {
					if name == "bin" || name == "share" || name == "lib" {
						continue
					}
					stack = append(stack, srcpath)
				} else {
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
						copyFile(srcpath, path.Join(dst, srcpath))
						// } else {
						// 	fmt.Printf("skipping %s\n", name)
					}
				}
			}
		}
	}
}

// 445