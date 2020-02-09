#!/bin/sh
#
# usage:
#	./bin/create.sh {project_name}
#

ROOT=`dirname "$0"`
ROOT=`cd "$ROOT"/.. ; pwd`
PROJECT_NAME=$1

if [[ "$PROJECT_NAME" == *\/* ]] || [[ "$string" == *\\* ]]
then
	echo "project name cannot be a path."
	exit -1
fi

. ${ROOT}/.env

PROJECT="${BUILDER_SHARED_FOLDER}/${PROJECT_NAME}"
if [ ! -d "${PROJECT}" ]
then
	echo "${PROJECT} does not exist. Creating default project."
	mkdir "${PROJECT}"

cat << EOF > "${PROJECT}/main.cpp"
#include <iostream>

int main( int argc, char **argv )
{
}
EOF

cat << 'EOF' > "${PROJECT}/CMakeLists.txt"
cmake_minimum_required(VERSION 3.16)
project(PROJECT_NAME)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enable_testing()

add_executable(PROJECT_NAME)
target_sources(PROJECT_NAME PRIVATE
	main.cpp
)
EOF

perl -pi -e "s|PROJECT_NAME|$PROJECT_NAME|" "${PROJECT}/CMakeLists.txt"


fi

echo "creating workspace for ${PROJECT}"

mkdir -p "~/Workspaces"
TEMPLATE="${ROOT}/bin/TEMPLATE.code-workspace"
WORKSPACE="~/Workspaces/${PROJECT_NAME}.code-workspace"

if [ -f "${WORKSPACE}" ]
then
	echo "${WORKSPACE} already exists"
	exit -1;
fi

echo "workspace file : ${WORKSPACE}"
perl -p -e "s|PROJECT|$PROJECT|;s|BUILD_RIG|${ROOT}|" "${TEMPLATE}" > "${WORKSPACE}"
