#!/bin/sh
#
# usage:
#	./bin/create.sh {project_name}
#

ROOT=`dirname "$0"`
ROOT=`cd "$ROOT"/.. ; pwd`
NAME=$1

if [[ "$NAME" == *\/* ]] || [[ "$NAME" == *\\* ]]
then
	echo "project name cannot be a path."
	exit -1
fi

. ${ROOT}/.env

PROJECT_PATH="${WORKSPACE_SHARED_FOLDER}/${NAME}"
if [ ! -d "${PROJECT_PATH}" ]
then
	echo "${PROJECT_PATH} does not exist. Creating default project."
	mkdir "${PROJECT_PATH}"

cat << EOF > "${PROJECT_PATH}/main.cpp"
#include <iostream>

int main( int argc, char **argv )
{
	std::cout << "hello world" << std::endl;
}
EOF

cat <<EOF > "${PROJECT_PATH}/CMakeLists.txt"
cmake_minimum_required(VERSION 3.16)
project(${NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# enable_testing()

add_executable(${NAME})
target_sources(${NAME} PRIVATE
	main.cpp
)
EOF

cat <<EOF > "${PROJECT_PATH}/.gitignore"
.tosync
EOF

fi

echo "creating workspace for ${PROJECT_PATH}"

TEMPLATE="${ROOT}/bin/TEMPLATE.code-workspace"
mkdir -p ~/Workspaces
WORKSPACE=`cd ~/Workspaces ; pwd`
WORKSPACE=${WORKSPACE}/${NAME}.code-workspace

if [ -f "${WORKSPACE}" ]
then
	echo "${WORKSPACE} already exists"
	exit -1;
fi

which cygpath.exe > /dev/null
if [ $? = 0 ]
then
	ROOT=`cygpath.exe -m "${ROOT}"`
fi
echo "workspace file : ${WORKSPACE}"
perl -p -e "s|PROJECT_PATH|$PROJECT_PATH|;s|BUILD_RIG|${ROOT}|" "${TEMPLATE}" > "${WORKSPACE}"
