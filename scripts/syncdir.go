//
// - scan: {path}
// - sync: {src} {dst}
// - clean: -clean {path}
// - backsync: -backsync {dst} {src}
// - headers: -headers {dst} {paths}...

package main

import (
	"bufio"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
)

func main() {
	cleanPtr := flag.Bool("clean", false, "-clean {dst}")
	backsyncPtr := flag.Bool("backsync", false, "-backsync {dst} {src}")
	headersPtr := flag.Bool("headers", false, "-headers {dst} {paths}...")

	flag.Parse()

	if *cleanPtr && len(flag.Args()) == 1 {
		panic("clean")
	}
	if *backsyncPtr && len(flag.Args()) == 2 {
		panic("backsync")
	}
	if *headersPtr && len(flag.Args()) >= 2 {
		panic("headers")
	}
	if len(flag.Args()) == 1 {
		if updateScan(flag.Args()[0]) {
			os.Exit(0)
		}
	}
	if len(flag.Args()) == 2 {
		if sync(flag.Args()[0], flag.Args()[1]) {
			os.Exit(0)
		}
	}
	panic("error")
}

type ignoreRule struct {
	negate  bool
	dirOnly bool
	pattern *regexp.Regexp
}
type ignoreFile struct {
	rules []ignoreRule
}

func hasGitIgnore(files []os.FileInfo) bool {
	for _, v := range files {
		if v.Name() == ".gitignore" {
			return true
		}
	}
	return false
}
func parseGitIgnore(path string) ignoreFile {

	file, err := os.Open(path)
	check(err)
	defer file.Close()

	var oneFile ignoreFile

	lines := bufio.NewScanner(file)
	for lines.Scan() {

		pattern := lines.Text()
		if len(pattern) == 0 ||
			pattern[0] == '#' {
			continue
		}

		var rule ignoreRule
		if pattern[0] == '!' {
			rule.negate = true
			pattern = pattern[1:]
		}
		if pattern[len(pattern)-1] == '/' {
			rule.dirOnly = true
			pattern = pattern[:len(pattern)-1]
		}

		// glob to regex
		// 	collapse ***.. -> **
		// 	**  --> .*
		// 	* -> [^\/]*
		// 	? -> [^\/]
		// 	leading / -> ^

		originalPattern := pattern

		regex := ""
		if pattern[0] == '/' {
			regex += "^"
			pattern = pattern[1:]
		}

		escaping := false
		for i := 0; i < len(pattern); i++ {
			c := pattern[i]

			switch {
			case c == '.' || c == '(' || c == ')' || c == '|' ||
				c == '+' || c == '^' || c == '$' || c == '@' || c == '%':
				regex += "\\" + string(c)
			case c == '*':
				if escaping {
					regex += "\\*"
				} else if (i+1) < len(pattern) && pattern[i+1] == '*' {
					i++
					//! @todo: consume all '*'
					regex += ".*"
				} else {
					regex += "[^\\/]*"
				}
			case c == '?':
				if escaping {
					regex += "\\?"
				} else {
					regex += "[^\\/]"
				}
			case c == '{':
				regex += "\\{"
			case c == '\\':
				if escaping {
					regex += "\\\\"
					escaping = false
				} else {
					escaping = true
				}
				continue
			default:
				regex += string(c)
			}
			escaping = false
		}
		fmt.Printf("%s = %s\n", originalPattern, regex)

		rule.pattern, err = regexp.Compile(regex)
		check(err)

		oneFile.rules = append(oneFile.rules, rule)
	}
	return oneFile
}
func shouldSkipFile(name string, relpath string, isDir bool, ignoreRules []ignoreFile) bool {
	if name == ".tosync" || name == ".vscode" || strings.HasPrefix(name, ".git") {
		return true
	}
	ignore := false
	for _, file := range ignoreRules {
		for _, rule := range file.rules {
			if rule.pattern.MatchString(relpath) {
				switch {
				case rule.negate:
					ignore = false
				case rule.dirOnly && isDir:
					return true
				default:
					ignore = true
				}
			}
		}
	}
	return ignore
}

func updateScan(src string) bool {

	if !isDirectory(src) {
		return false
	}

	fmt.Printf("scanning %s\n", src)

	file, err := os.Create(src + "/.tosync")
	check(err)
	defer file.Close()
	w := bufio.NewWriter(file)
	defer w.Flush()

	ignoreRules := make([]ignoreFile, 0, 10)
	//! @todo: user ignore file too ?
	if isFile(src + "/.git/info/exclude") {
		ignoreRules = append(ignoreRules, parseGitIgnore(src+"/.git/info/exclude"))
	}

	stack := make([]string, 0, 64)
	stack = append(stack, src)
	for len(stack) > 0 {
		n := len(stack)
		f := stack[n-1]
		stack = stack[:n-1]

		shouldPopIgnoreRules := false

		files, err := ioutil.ReadDir(f)
		check(err)
		if hasGitIgnore(files) {
			ignoreRules = append(ignoreRules, parseGitIgnore(f+"/.gitignore"))
			shouldPopIgnoreRules = true
		}
		for _, finfo := range files {
			fullpath := f + "/" + finfo.Name()
			relpath := fullpath[len(src)+1:]
			if shouldSkipFile(finfo.Name(), relpath, finfo.IsDir(), ignoreRules) {
				continue
			}
			switch {
			case (finfo.Mode() & os.ModeSymlink) != 0:
				ln, err := os.Readlink(fullpath)
				check(err)
				w.WriteString(strconv.FormatInt(finfo.ModTime().Unix(), 10))
				w.WriteString(" ")
				w.WriteString(relpath)
				w.WriteString(" -> ")
				w.WriteString(ln)
				w.WriteString("\n")
			case finfo.IsDir():
				stack = append(stack, fullpath)
			default:
				w.WriteString(strconv.FormatInt(finfo.ModTime().Unix(), 10))
				w.WriteString(" ")
				w.WriteString(relpath)
				w.WriteString("\n")
			}
		}
		if shouldPopIgnoreRules {
			ignoreRules = ignoreRules[:len(ignoreRules)-1]
		}
	}
	return true
}

func syncFolder(src, dst string) bool {

	if !isDirectory(src) {
		return false
	}

	fmt.Printf("sync'ing %s to %s\n", src, dst)

	// 	open my $tosync_src, '<', "$src/.tosync";
	// 	chomp(my @lines = <$tosync_src>);
	// 	close $tosync_src;

	// 	open my $lastsync_dst, '<', "$dst/.lastsync";
	// 	my $lastSync = <$lastsync_dst>;
	// 	close $lastsync_dst;
	//     $lastSync = $lastSync + 0;

	//     my $latest = 0;
	//     foreach ( @lines )
	//     {
	//         if ( /^(\d+)\s+(.+)$/ )
	//         {
	//             my $timestamp = $1 + 0;
	//             my $relpath = $2;

	//             if ( $timestamp > $lastSync )
	//             {
	// 				my $srcFile = "$src/$relpath";
	// 				my $dstFile = "$dst/$relpath";
	// 				my $dstDirname = dirname($dstFile);
	// 				if ( ! -d "$dstDirname" )
	// 				{
	// 					make_path( $dstDirname );
	// 				}
	//                 print "$relpath\n";
	//                 if ( -l "$srcFile" )
	//                 {
	//                     my $ln = readlink "$srcFile";
	//                     `cd "$dstDirname" ; ln -s "$ln"`;
	//                 }
	//                 else
	//                 {
	//     				copy( $srcFile, $dstFile );
	//                     if ( -x "$srcFile" )
	//                     {
	//                         chmod 0755, "$dstFile";
	//                     }
	//                 }
	//             }
	//             if ( $timestamp > $latest )
	//             {
	//                 $latest = $timestamp;
	//             }
	//         }
	//     }
	// 	open my $file, '>', "$dst/.lastsync";
	//     printf $file "$latest\n";
	// 	close $file;
}

func isDirectory(path string) bool {
	fileInfo, err := os.Stat(path)
	if err != nil {
		return false
	}
	return fileInfo.IsDir()
}
func isFile(path string) bool {
	fileInfo, err := os.Stat(path)
	if err != nil {
		return false
	}
	return !fileInfo.IsDir()
}

func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}
