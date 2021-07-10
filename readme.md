
## Solution for working on large cross-platform cmake-based c++ projects using docker
---

### The problem



### Goals
- a single source code tree
- source code edition on the host with vscode
- build & debug in different linux containers
- build & debug natively on host (macos or windows)

### Setup

### Usage


## how it works

- sync:
	- host to container


./bin/create.sh /path/to/folder

build_rig has a build driver script that does:
	- synchronise folder
	- execute itself in the container
	- run build script from target

the build driver needs:
	- path to target project
	- how to build target

# todo:
- some c++ tools
- msvc wine ?
