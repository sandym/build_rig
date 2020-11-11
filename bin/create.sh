#!/bin/sh
#
# usage:
#	./bin/create.sh {project_name}
#

ROOT=`dirname "$0"`
ROOT=`cd "$ROOT"/.. ; pwd`
PROJECT_NAME=$1

if [[ "${PROJECT_NAME}" == *\/* ]] || [[ "${PROJECT_NAME}" == *\\* ]]
then
	echo "project name cannot be a path."
	exit -1
fi

if [[ "${PROJECT_NAME}" == "" ]]
then
	echo "need a project name."
	exit -1
fi

. ${ROOT}/.env

PROJECT_PATH="${WORKSPACE_SHARED_FOLDER}/${PROJECT_NAME}"
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
project(${PROJECT_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# enable_testing()

add_executable(${PROJECT_NAME})
target_sources(${PROJECT_NAME} PRIVATE
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
WORKSPACE=${WORKSPACE}/${PROJECT_NAME}.code-workspace

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
perl -p -e "s|PROJECT_PATH|$PROJECT_PATH|;s|BUILD_RIG|${ROOT}|;s|PROJECT_NAME|${PROJECT_NAME}|" "${TEMPLATE}" > "${WORKSPACE}"
