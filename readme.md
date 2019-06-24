
## My solution for working on large c++ projects with docker
---

### Goals
- source code edition on my host
- build & debug in a container

### Accessing the code

### Building

### Access to headers

### Debugging

### Extensions & customisation

- running tests
- static analyser

## syncdir.go

- sync:
	- mac to linux
	- mac to windows
	- windows to linux

## how to link build_rig and target project ?

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
	7. document
	8. extensions ?
	9. test different distro / build system
		- centos / ubuntu / alpine
		- cmake / make
		- g++4.8.5 - g++8

```
{
   "folders": [
           {
                   "path": "build_rig"
           },
           {
                   "path": "~/work/llvm_src"
           }
   ]
}
```
