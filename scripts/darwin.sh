#!/bin/sh

set -e

cd "$2"

if [ "$1" = "xcode" ]
then

	mkdir -p build/xcode
	cd build/xcode
	cmake -G Xcode ../../.
	open *.xcodeproj
	exit 0

fi

if [ "$1" = "xcode-clean" ]
then

	rm -rf build/xcode
	exit 0

fi

if [ "$1" = "clean" ]
then

	if [ -f build/darwin/build.ninja ]
	then
		cd build/darwin
		ninja clean
	else
		rm -rf build/darwin
	fi
	exit 0

fi

mkdir -p build/darwin
cd build/darwin
if [ ! -f build.ninja ]
then
	cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=on ../../.
fi

ninja

if [ "$1" = "test" ]
then
	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
fi
