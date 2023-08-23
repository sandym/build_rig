#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

# build each image
cd "${IMAGES}"
for df in *.dockerfile ; do
	os="${df%.*}"
	echo "--> building ${os}"
	docker build \
		--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
		--build-arg NINJA_VERSION=${NINJA_VERSION} \
		-t ${os}_builder \
		-f ${df} .
done

# build centos9 as amd64 too, if we're on arm64
if [ "$(uname -m)" = "arm64" ]
then
	echo "--> building centos9:amd64"
	docker build \
		--platform=linux/amd64 \
		--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
		--build-arg NINJA_VERSION=${NINJA_VERSION} \
		-t centos9_amd64_builder \
		-f centos9.dockerfile .
fi

docker volume create build_rig_work
