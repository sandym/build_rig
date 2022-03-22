#!/bin/sh
#
# usage:
#	./bin/create.sh {project_path}
#

ROOT=$(dirname "$0")
ROOT=$(cd "${ROOT}"/.. ; pwd)
PROJECT_PATH=$1
PROJECT_NAME=$(basename "${PROJECT_PATH}")
PROJECT_PATH=$(cd "$(dirname "${PROJECT_PATH}")"; pwd)/${PROJECT_NAME}

if [[ "${PROJECT_PATH}" == "" ]]
then
	echo "need a project path."
	exit -1
fi

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
cmake_minimum_required(VERSION 3.22)
project(${PROJECT_NAME})

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# enable_testing()

add_executable(${PROJECT_NAME})
target_sources(${PROJECT_NAME} PRIVATE
	main.cpp
)
EOF

cp "${ROOT}/.editorconfig" "${PROJECT_PATH}/.editorconfig"
cp "${ROOT}/bin/.clang-format" "${PROJECT_PATH}/.clang-format"

cd "${PROJECT_PATH}"
git init

fi

echo "creating workspace for ${PROJECT_PATH}"

TEMPLATE="${ROOT}/bin/TEMPLATE.code-workspace"
mkdir -p ~/Workspaces
WORKSPACE=$(cd ~/Workspaces ; pwd)
WORKSPACE=${WORKSPACE}/${PROJECT_NAME}.code-workspace

if [ -f "${WORKSPACE}" ]
then
	echo "${WORKSPACE} already exists"
	exit -1;
fi

echo "workspace file : ${WORKSPACE}"

export PROJECT_PATH=${PROJECT_PATH}
export BUILD_RIG=${ROOT}
export PROJECT_NAME=${PROJECT_NAME}
envsubst < "${TEMPLATE}" > "${WORKSPACE}"
