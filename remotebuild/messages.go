package main

import (
	"encoding/gob"
	"fmt"
)

type fileToSync struct {
	Relpath string
	T       int64
}
type symLinkToSync struct {
	Relpath string
	T       int64
	Target  string
}
type revToSync struct {
	Relpath  string
	Revision string
}

// client send a scanMsg
type scanFolderData struct {
	Dst  string
	Scan []interface{} // fileToSync, symLinkToSync or revToSync
}
type scanMsg []scanFolderData

// server reply with a requestMsg
type requestData struct {
	Dst      string
	Relpaths []string
}
type requestMsg []requestData

// client send a bunch of fileMsg
type fileMsg struct {
	Dst          string
	Relpath      string
	IsExe        bool
	IsCompressed bool
	Data         []byte
}

// followed by a buildCmdMsg
type buildCmdMsg struct {
	BuildCmd []string
}

// server send a buildStartingMsg when ready to start the build
type buildStartingMsg struct {
}

// client just forward server stdout until server quits

func registerMessages() {
	gob.Register(fileToSync{})
	gob.Register(symLinkToSync{})
	gob.Register(revToSync{})
	gob.Register(scanMsg{})
	gob.Register(requestMsg{})
	gob.Register(fileMsg{})
	gob.Register(buildCmdMsg{})
	gob.Register(buildStartingMsg{})
}

func toString(o interface{}) string {
	switch o := o.(type) {
	case fileToSync:
		return "fileToSync: " + o.Relpath
	case symLinkToSync:
		return "symLinkToSync: " + o.Relpath + "->" + o.Target
	case revToSync:
		return "revToSync: " + o.Relpath
	case scanMsg:
		nbOfFiles := 0
		for _, scan := range o {
			nbOfFiles += len(scan.Scan)
		}
		return fmt.Sprintf("scanMsg: %d files for %d folders", nbOfFiles, len(o))
	case buildCmdMsg:
		return "buildCmdMsg"
	case buildStartingMsg:
		return "buildStartingMsg"
	case requestMsg:
		nbOfFiles := 0
		for _, request := range o {
			nbOfFiles += len(request.Relpaths)
		}
		return fmt.Sprintf("requestMsg: %d files for %d folders", nbOfFiles, len(o))
	case fileMsg:
		return "fileMsg: " + o.Relpath
	}
	return fmt.Sprintf("%v", o)
}
