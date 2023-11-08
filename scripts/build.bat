
@echo off
set triplet=%1
set project=%2
for /F "delims=" %%i in ("%project%") do set project_name=%%~ni

for /f "tokens=1,2,3 delims=-" %%A in ("%triplet%") Do (
	set action=%%A
	set toolset=%%B
	set type=%%C
)

echo   Windows %triplet% %project_name%
echo:

@REM Set build tool
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -startdir=none -arch=arm64 -host_arch=arm64

set BIN_DIR=C:/work/%project_name%/%type%

@REM do build
echo building in %BIN_DIR%
echo:

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
cd %BIN_DIR%

if not exist build.ninja (
	cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug C:/work/%project_name%/src
)

ninja

echo:
echo   done Windows %triplet% %project_name%
