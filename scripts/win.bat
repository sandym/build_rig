@echo off

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

scripts\syncdir_win -sync "%1\%3" "c:\p\%3"

c:
cd c:\p

if not exist %3%_build (
	mkdir %3%_build
)
cd %3%_build

if %2 == build (

if not exist debug (
	mkdir debug
)
cd debug
if not exist build.ninja (
	cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=on "c:\p\%3"
)
ninja

)

if %2 == test (

if not exist debug (
	mkdir debug
)
cd debug
if not exist build.ninja (
	cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=on "c:\p\%3"
)
ninja

ctest --output-on-failure --parallel %PROCESSOR_LEVEL%

)

if %2 == VS (

if not exist vs (
	mkdir vs
)
cd vs
cmake -G "Visual Studio 16 2019" "c:\p\%3"

)

if %2 == clean (

if exist debug\build.ninja (
	cd debug
	ninja clean
	exit 0
)
rm -rf debug

)
