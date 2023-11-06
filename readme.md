
## Solution for working on large cross-platform cmake-based c++ projects using docker (macos)
---

### The problem



### Goals
- A single source code tree (done)
- Source code edition on the host (done)
- Build & debug in different linux containers (done)
- Build & debug natively on macos host (done)
- Support x86_64 on apple silicon (done)
- Support Windows in a VM (todo)

### Setup

```
> colima start --cpu 6 --memory 24 --disk 120 --vm-type=vz --vz-rosetta
```

or docker-desktop.

### Usage


## how it works

- sync:
	- host to container

```
./bin/create.sh /path/to/folder
```

build_rig has a build driver script that does:
	- synchronise source folder
	- execute itself in the container
	- run build script from target

the build driver needs:
	- path to target project
	- how to build target

# todo:
- some c++ tools
