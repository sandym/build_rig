#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

# build each image
cd "${IMAGES}"
for d in * ; do
	if [ -d "${d}" ]
	then
		cd ${d}
		echo "--> building ${d}"
		docker build \
			--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
			--build-arg NINJA_VERSION=${NINJA_VERSION} \
			-t ${d}_builder .
		cd ..
	fi
done

# build centos9 as amd64 too, if we're on arm64
if [ "$(uname -m)" = "arm64" ]
then

	cd centos9
	echo "--> building centos9:amd64"
	docker build \
		--platform=linux/amd64 \
		--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
		--build-arg NINJA_VERSION=${NINJA_VERSION} \
		-t centos9_amd64_builder .
	cd ..

fi

docker volume create build_rig_work
