#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

DRY_RUN=0

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

function dockerBuild
{
	echo "docker build $@"
	if [ $DRY_RUN = 0 ]
	then
		docker build $@
	fi
}

# build each image
cd "${IMAGES}"
for df in *.dockerfile ; do
	os="${df%.*}"
	echo "--> building ${os}"
	dockerBuild \
		--pull \
		--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
		--build-arg NINJA_VERSION=${NINJA_VERSION} \
		-t ${os}_builder:$(uname -m) \
		-f ${df} .
done

# build as amd64 too, if we're on arm64
for df in *.dockerfile ; do
	os="${df%.*}"
	echo "--> building ${os}:amd64"
	dockerBuild \
		--pull \
		--platform=linux/amd64 \
		--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
		--build-arg NINJA_VERSION=${NINJA_VERSION} \
		-t ${os}_builder:amd64 \
		-f ${df} .
done

if [ $DRY_RUN = 0 ]
then
	docker volume create build_rig_work
fi
