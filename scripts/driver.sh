#!/bin/sh
#
# platform: darwin or platform name
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

SERVICE=${PLATFORM//:/_}
SERVICE=${SERVICE%_arm64}

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
	"docker", "compose", "exec", "-i",
	"${SERVICE}"
],
"copy": [
  "docker", "compose", "cp",
  "${SYNCDIR}/syncdir_linux_arm64",
  "${SERVICE}:/tmp/syncdir_linux_arm64"
],
"remote": "/tmp/syncdir_linux_arm64",

"compress": false
}
END_HEREDOC
)

docker compose ps --services | grep "^${SERVICE}$" > /dev/null
if [ $? -ne 0 ]
then
	echo "--> Starting container ${CONTAINER_NAME}"
	docker compose up -d ${SERVICE}
	sleep 5
fi

# echo "${CONFIG}"
"${SYNCDIR}/syncdir_host" -config "${CONFIG}"

docker compose exec -ti ${SERVICE} \
	/scripts/build.sh \
	${PLATFORM} \
	${TRIPLET} \
	/work/${PROJECT_NAME}

fi
