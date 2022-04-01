#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

cd "${IMAGES}"
for d in * ; do
	if [ -d "${d}" ]
	then
		cd ${d}
		docker build \
			--build-arg CMAKE_VERSION=${CMAKE_VERSION} \
			--build-arg NINJA_VERSION=${NINJA_VERSION} \
			-t ${d}_builder .
		cd ..
	fi
done

docker volume create build_rig_work
