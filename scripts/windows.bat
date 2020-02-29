
echo off

set PROJECT_PATH=%2%
FOR /F "tokens=* USEBACKQ" %%F IN (`basename %PROJECT_PATH%`) DO (
	SET PROJECT_NAME=%%F
)
set BUILD_DIR=c:/w/%PROJECT_NAME%

if "%1"=="vs" (

	mkdir "%BUILD_DIR%/VS"
	cd "%BUILD_DIR%/VS"
	cmake -G "Visual Studio 16 2019" -A x64 "%PROJECT_PATH%"
	cmake --open .
	exit 0

)

if "%1"=="vs-clean" (

	rm -rf "%BUILD_DIR%/VS"
	exit 0

)

if "%1"=="clean" (

REM 	if [ -f ~/darwin_build/"${PROJECT_NAME}"/debug/build.ninja ]
REM 	then
REM 		cd ~/darwin_build/"${PROJECT_NAME}"/debug
REM 		ninja clean
REM 	else
REM 		rm -rf ~/darwin_build/"${PROJECT_NAME}"/debug
REM 	fi
REM 	exit 0

)

mkdir "%BUILD_DIR%/debug"
cd "%BUILD_DIR%/debug"
REM if [ ! -f build.ninja ]
REM then
REM 	cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=on ${PROJECT_PATH}
REM fi

REM time ninja

if "%1"=="test" (
REM 	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
)

echo ""
echo "done vs %1"
