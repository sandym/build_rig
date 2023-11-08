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
cd "${REMOTEBUILD}"
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
  "${REMOTEBUILD}/remotebuild_win",
  "${WINHOST}:C:/work/remotebuild_win.exe"
],
"remote": "C:/work/remotebuild_win.exe",

"compress": false,

"build_cmd": [
  "C:/scripts/build.bat",
  "${TRIPLET}",
  "C:/work/${PROJECT_NAME}"
]
}
END_HEREDOC
)

else

# @todo: handle k8s ?

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
	docker run --rm --init -ti -d \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${PLATFORM} \
		${PLATFORM} sleep infinity
	sleep 5
fi

fi

# echo "${CONFIG}"

"${REMOTEBUILD}/remotebuild_host" -config "${CONFIG}"
