package main

import (
	"flag"
)

// BuildID should change for each build
var BuildID string = "default"
var debugOn = false

func main() {

	configPtr := flag.String("config", "", "-config {config}")
	debugOnPtr := flag.Bool("debug", false, "output debug info")
	flag.Parse()
	debugOn = *debugOnPtr

	registerMessages()

	if len(*configPtr) > 0 {
		runClient(*configPtr)
	} else {
		runServer()
	}
}
