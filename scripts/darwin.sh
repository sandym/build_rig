#!/bin/sh

set -e

PROJECT_PATH="$2"
PROJECT_NAME=`basename "${PROJECT_PATH}"`
BUILD_DIR="~/darwin_build/${PROJECT_NAME}"

if [ "$1" = "xcode" ]
then

	mkdir -p "${BUILD_DIR}/xcode"
	cd "${BUILD_DIR}/xcode"
	cmake -G Xcode ${PROJECT_PATH}
	open *.xcodeproj
	exit 0

fi

if [ "$1" = "xcode-clean" ]
then

	rm -rf "${BUILD_DIR}/xcode"
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
	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
fi

echo ""
echo "done macos $1"
