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

cd "${IMAGES}"

# build alpine_builder
echo "--> building alpine"
dockerBuild \
	--pull \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t alpine_builder:arm64 \
	-f alpine.dockerfile .

echo "--> building alpine x86_64"
dockerBuild \
	--pull \
	--platform=linux/amd64 \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t alpine_builder:x86_64 \
	-f alpine.dockerfile .

# build ubuntu_builder
echo "--> building ubuntu"
dockerBuild \
	--pull \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t ubuntu_builder:arm64 \
	-f ubuntu.dockerfile .

echo "--> building ubuntu x86_64"
dockerBuild \
	--pull \
	--platform=linux/amd64 \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t ubuntu_builder:x86_64 \
	-f ubuntu.dockerfile .

# build centos9_builder
echo "--> building centos9"
dockerBuild \
	--pull \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t centos9_builder:arm64 \
	-f centos9.dockerfile .

echo "--> building centos9 x86_64"
dockerBuild \
	--pull \
	--platform=linux/amd64 \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t centos9_builder:x86_64 \
	-f centos9.dockerfile .

# build centos10_builder
echo "--> building centos10"
dockerBuild \
	--pull \
	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
	--build-arg NINJA_VERSION=${NINJA_VERSION} \
	-t centos10_builder:arm64 \
	-f centos10.dockerfile .

# echo "--> building centos10 x86_64"
# dockerBuild \
# 	--pull \
# 	--platform=linux/amd64 \
# 	--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
# 	--build-arg NINJA_VERSION=${NINJA_VERSION} \
# 	-t centos10_builder:x86_64 \
# 	-f centos10.dockerfile .

if [ $DRY_RUN = 0 ]
then
	docker volume create build_rig_work
fi
