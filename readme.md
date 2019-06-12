
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


```
.
|-- builder
|   `-- Dockerfile
|-- docker-compose.yml  <-- need to know the shared folder
|-- readme.md
|-- .vscode
|   |-- launch.json
|   `-- tasks.json
`-- scripts
    |-- build_driver.sh
    `-- syncdir.go
```

- document customisation points:
	- shared folder
	- build script
	- sync point(s)
	- debugging


# todo:
	6. get syncback to work
	7. document
	8. extensions ?
	9. test different distro / build system
		- centos / ubuntu / alpine
		- cmake / make
		- g++4.8.5 - g++8
