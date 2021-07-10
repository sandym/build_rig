package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"path"
	"runtime"
)

type FolderToCopy struct {
	Src string `json:"src"`
	Dst string `json:"dst"`
}

type config struct {
	Folders       []FolderToCopy `json:"folders"`
	TransportCmd  []string       `json:"transport"`
	CopyCmd       []string       `json:"copy"`
	RemotePath    string         `json:"remote"`
	CompressFiles bool           `json:"compress"`
	BuildCmd      []string       `json:"build_cmd"`
}

func (config *config) srcForDst(dst string) string {
	for _, folder := range config.Folders {
		if folder.Dst == dst {
			return folder.Src
		}
	}
	return ""

}

func readConfig(configInput string) config {
	data, err := ioutil.ReadFile(configInput)
	if err != nil {
		// not a file ?
		data = []byte(configInput)
	}

	conf := config{}
	err = json.Unmarshal(data, &conf)
	if err != nil {
		log.Fatalf("ERROR cannot parse \"%s\", %s", configInput, err)
	}
	return conf
}
func isDirectory(path string) bool {
	fileInfo, err := os.Stat(path)
	return err == nil && fileInfo.IsDir()
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
