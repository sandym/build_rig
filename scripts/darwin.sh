#!/bin/sh

set -e

PROJECT="$2"

if [ "$1" = "xcode" ]
then

	mkdir -p ~/darwin_build/xcode
	cd ~/darwin_build/xcode
	cmake -G Xcode ${PROJECT}
	open *.xcodeproj
	exit 0

fi

if [ "$1" = "xcode-clean" ]
then

	rm -rf ~/darwin_build/xcode
	exit 0

fi

if [ "$1" = "clean" ]
then

	if [ -f ~/darwin_build/debug/build.ninja ]
	then
		cd ~/darwin_build/debug
		ninja clean
	else
		rm -rf ~/darwin_build/debug
	fi
	exit 0

fi

mkdir -p ~/darwin_build/debug
cd ~/darwin_build/debug
if [ ! -f build.ninja ]
then
	cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=on ${PROJECT}
fi

ninja

if [ "$1" = "test" ]
then
	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
fi
