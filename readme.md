
## Solution for working on large cross-platform cmake-based c++ projects using docker (macos)
---

### The problem



### Goals
- a single source code tree
- source code edition on the host
- build & debug in different linux containers
- build & debug natively on macos  host

### Setup

```
> colima start --cpu 6 --memory 24 --disk 120 --vm-type=vz --vz-rosetta --kubernetes
```

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
