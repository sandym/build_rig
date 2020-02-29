#!/bin/sh
#
# usage:
#	./bin/create.sh {project_name}
#

ROOT=`dirname "$0"`
ROOT=`cd "$ROOT"/.. ; pwd`
PROJECT=$1

if [[ "$PROJECT" == *\/* ]] || [[ "$PROJECT" == *\\* ]]
then
	echo "project name cannot be a path."
	exit -1
fi

. ${ROOT}/.env

PROJECT_FOLDER="${WORKSPACE_SHARED_FOLDER}/${PROJECT}"
if [ ! -d "${PROJECT_FOLDER}" ]
then
	echo "${PROJECT_FOLDER} does not exist. Creating default project."
	mkdir "${PROJECT_FOLDER}"

cat << EOF > "${PROJECT_FOLDER}/main.cpp"
#include <iostream>

int main( int argc, char **argv )
{
}
EOF

cat <<EOF > "${PROJECT_FOLDER}/CMakeLists.txt"
cmake_minimum_required(VERSION 3.16)
project(${PROJECT})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# enable_testing()

add_executable(${PROJECT})
target_sources(${PROJECT} PRIVATE
	main.cpp
)
EOF

fi

echo "creating workspace for ${PROJECT_FOLDER}"

TEMPLATE="${ROOT}/bin/TEMPLATE.code-workspace"
mkdir -p ~/Workspaces
WORKSPACE=`cd ~/Workspaces ; pwd`
WORKSPACE=${WORKSPACE}/${PROJECT}.code-workspace

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
perl -p -e "s|PROJECT|$PROJECT_FOLDER|;s|BUILD_RIG|${ROOT}|" "${TEMPLATE}" > "${WORKSPACE}"
