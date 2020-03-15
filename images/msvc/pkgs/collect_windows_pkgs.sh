#!/bin/sh

echo "---> clean up"
rm -rf *.tar.gz

# cmake
echo "---> packaging cmake"
cmake -E copy_directory "C:\Program Files\CMake" CMake
cmake -E tar cfz CMake.tar.gz CMake
cmake -E remove_directory CMake

# git
echo "---> packaging git"
cmake -E copy_directory "C:\Program Files\Git" Git
cmake -E tar cfz Git.tar.gz Git
cmake -E remove_directory Git

# VS2019
echo "---> packaging VS2019"
cmake -E copy_directory "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools" BuildTools
find BuildTools -type f -name 'VCTIP.exe' -exec rm -rf \{\} \;
find BuildTools -type f -name 'Llvm' -exec rm -rf \{\} \;
find BuildTools -type f -name 'Hostx86' -exec rm -rf \{\} \;
cmake -E tar cfz VS2019.tar.gz BuildTools
cmake -E remove_directory BuildTools

# SDK
echo "---> packaging WinSDK"
cmake -E copy_directory "C:\Program Files (x86)\Windows Kits\10" SDK
find SDK -type f -name 'arm*' -exec rm -rf \{\} \;
cmake -E tar cfz SDK.tar.gz SDK
cmake -E remove_directory SDK
