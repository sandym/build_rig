#!/bin/sh
#
# platform: darwin or container name
#

PLATFORM=$1
TRIPLET=$2
PROJECT=$3
SCRIPTS=$(dirname "$0")
SCRIPTS=$(cd "${SCRIPTS}" ; pwd)

if [ "${PLATFORM}" = "darwin" ]
then

	exec "${SCRIPTS}/build.sh" ${PLATFORM} ${TRIPLET} "${PROJECT}"

fi

PROJECT_NAME=$(basename "${PROJECT}")
REMOTEBUILD=$(cd "${SCRIPTS}/../remotebuild" ; pwd)

# build syncdir if needed
"${REMOTEBUILD}/build.sh"

if [ "${PLATFORM}" = "windows" ]
then

	echo "@todo ${PLATFORM}"
	exit 1

fi

# @todo: handle k8s ?

CONFIG=$(cat <<END_HEREDOC
{
"folders": [
  {
    "src": "${PROJECT}",
    "dst": "/work/$PROJECT_NAME/src"
  },
  {
    "src": "${SCRIPTS}",
    "dst": "/scripts"
  }
],

"transport": [
	"docker", "exec", "-i",
	"${PLATFORM}"
],
"copy": [
  "docker", "cp",
  "${REMOTEBUILD}/remotebuild_linux",
  "${PLATFORM}:/tmp/remotebuild_linux"
],
"remote": "/tmp/remotebuild_linux",

"compress": false,

"build_cmd": [
  "/scripts/build.sh",
  "${PLATFORM}",
  "${TRIPLET}",
  "/work/${PROJECT_NAME}"
]
}
END_HEREDOC
)

docker ps --filter "name=${PLATFORM}" | grep ${PLATFORM} > /dev/null
if [ $? -ne 0 ]
then
	echo "--> Starting container ${PLATFORM}"
	docker run --rm -ti -d \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${PLATFORM} \
		${PLATFORM} sleep infinity
	sleep 5
fi

# echo "${CONFIG}"

"${REMOTEBUILD}/remotebuild_host" -config "${CONFIG}"
