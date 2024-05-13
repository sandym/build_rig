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
SYNCDIR=$(cd "${SCRIPTS}/../syncdir" ; pwd)

# build syncdir if needed
cd "${SYNCDIR}"
make

if [ "${PLATFORM}" = "windows" ]
then

WINHOST="sandy-win"

CONFIG=$(cat <<END_HEREDOC
{
"folders": [
  {
    "src": "${PROJECT}",
    "dst": "C:/work/${PROJECT_NAME}/src"
  },
  {
    "src": "${SCRIPTS}",
    "dst": "C:/scripts"
  }
],

"transport": [
	"ssh", "${WINHOST}"
],
"copy": [
  "scp",
  "${SYNCDIR}/syncdir_win_arm64",
  "${WINHOST}:C:/work/syncdir_win_arm64.exe"
],
"remote": "C:/work/syncdir_win_arm64.exe",

"compress": false
}
END_HEREDOC
)

# echo "${CONFIG}"
"${SYNCDIR}/syncdir_host" -config "${CONFIG}"

ssh ${WINHOST} \
  C:/scripts/build.bat \
  ${TRIPLET} \
  C:/work/${PROJECT_NAME}

else

# @todo: handle k8s, ssh ?

CONTAINER_NAME=${PLATFORM//:/_}

CONFIG=$(cat <<END_HEREDOC
{
"folders": [
  {
    "src": "${PROJECT}",
    "dst": "/work/${PROJECT_NAME}/src"
  },
  {
    "src": "${SCRIPTS}",
    "dst": "/scripts"
  }
],

"transport": [
	"docker", "exec", "-i",
	"${CONTAINER_NAME}"
],
"copy": [
  "docker", "cp",
  "${SYNCDIR}/syncdir_linux_arm64",
  "${CONTAINER_NAME}:/tmp/syncdir_linux_arm64"
],
"remote": "/tmp/syncdir_linux_arm64",

"compress": false
}
END_HEREDOC
)

docker ps --filter "name=${CONTAINER_NAME}" | grep ${PLATFORM} > /dev/null
if [ $? -ne 0 ]
then
	echo "--> Starting container ${CONTAINER_NAME}"
	docker run --rm --init -ti -d \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${CONTAINER_NAME} \
		${PLATFORM} sleep infinity
	sleep 5
fi

# echo "${CONFIG}"
"${SYNCDIR}/syncdir_host" -config "${CONFIG}"

docker exec -ti ${CONTAINER_NAME} \
	/scripts/build.sh \
	${CONTAINER_NAME} \
	${TRIPLET} \
	/work/${PROJECT_NAME}

fi

