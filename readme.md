
## syncdir.go

- sync:
	- mac to linux
	- mac to windows
	- windows to linux

## how to link build_rig and target project ?

build_rig has a build driver script that does:
	- syncdir.py scan
	- re-execute itself in the container
	- syncdir.py sync
	- run build script from target

the build driver needs:
	- path to target project
	- how to build target


```
.
|-- builder
|   `-- Dockerfile
|-- docker-compose.yml  <-- need to know the shared folder
|-- readme.md
|-- vscode_tmpl
|   |-- launch.json <-- 
|   `-- tasks.json <-- folder to sync
`-- scripts
    |-- build_driver.sh <-- need to know container name, folder to sync and how to build
    `-- syncdir.py
```

- build/clean on builder
- debug on builder

- document customisation points:
	- shared folder
	- build script
	- sync point(s)
	- debugging


# todo:
	1. get sync and build to work
	2. check error messages path remapping
	3. get debugging to work
	4. sync shall use gitignore
	5. get clean to work
	6. get syncback to work
	7. document
	8. extensions ?
	9. test different distro / build system
		- centos / ubuntu / alpine
		- cmake / make
		- g++4.8.5 - g++8
