#!/bin/sh

set -e

PROJECT_PATH="$2"
PROJECT_NAME=`basename "${PROJECT_PATH}"`
BUILD_DIR="C:/p/${PROJECT_NAME}"

if [ "$1" = "vs" ]
then

	mkdir -p "${BUILD_DIR}/VS"
	cd "${BUILD_DIR}/VS"
	cmake -G "Visual Studio 16 2019" -A x64 ${PROJECT_PATH}
	cmake --open .
	exit 0

fi

if [ "$1" = "vs-clean" ]
then

	rm -rf "${BUILD_DIR}/VS"
	exit 0

fi

if [ "$1" = "clean" ]
then

	if [ -f "${BUILD_DIR}/debug/build.ninja" ]
	then
		cd "${BUILD_DIR}/debug"
		ninja clean
	else
		rm -rf "${BUILD_DIR}/debug"
	fi
	exit 0

fi

mkdir -p "${BUILD_DIR}/debug"
cd "${BUILD_DIR}/debug"
if [ ! -f build.ninja ]
then
	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=on ${PROJECT_PATH}
fi

time ninja

if [ "$1" = "test" ]
then
	ctest --output-on-failure --parallel $(nproc)
fi

echo ""
echo "done windows $1"
