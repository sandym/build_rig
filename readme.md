
## My solution for working on large cross-platform cmake-based c++ projects using docker
---

### Goals
- source code edition on my host
- build & debug in a container
- build on macos
- build on windows

### Accessing the code

### Building

### Access to headers

### Debugging

### Extensions & customisation

- running tests

## syncdir.go

- sync:
	- mac to linux
	- mac to windows
	- windows to linux

## how to link build_rig and target project ?

./bin/create.sh /path/to/folder

build_rig has a build driver script that does:
	- syncdir scan
	- re-execute itself in the container
	- syncdir sync
	- run build script from target

the build driver needs:
	- path to target project
	- how to build target


- document customisation points:
	- shared folder
	- build script
	- sync point(s)
	- debugging


# todo:
