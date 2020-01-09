#!/bin/sh

ROOT=`dirname "$0"`
ROOT=`cd "$ROOT"/.. ; pwd`

PROJECT=$1
if [ ! -d "${PROJECT}" ]
then
	echo "${PROJECT} is not a folder"
	exit -1
fi

PROJECT=`cd "${PROJECT}" ; pwd`
echo "creating workspace for ${PROJECT}"

WORKSPACE_NAME=`basename "${PROJECT}"`

TEMPLATE="${ROOT}/Workspaces/TEMPLATE.code-workspace"
WORKSPACE="${ROOT}/Workspaces/${WORKSPACE_NAME}.code-workspace"

if [ -f "${WORKSPACE}" ]
then
	echo "${WORKSPACE} already exists"
	exit -1;
fi

echo "workspace file : ${WORKSPACE}"
perl -p -e "s|PROJECT|$PROJECT|;s|BUILD_RIG|${ROOT}|" "${TEMPLATE}" > "${WORKSPACE}"
