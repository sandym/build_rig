#!/bin/sh

SCRIPTS=`dirname "$0"`
SCRIPTS=`cd "${SCRIPTS}" ; pwd`
ACTION=$1
PROJECT=$2

. "${SCRIPTS}/../.env"

syncdir()
{
	SYNCDIR=$1
	shift
	"${SCRIPTS}/${SYNCDIR}" $@
}

# in host

. "${SCRIPTS}/../.env"
BUILDER_SHARED_FOLDER=`basename "${BUILDER_SHARED_FOLDER}"`

# build syndir of needed
if [ ! -f "${SCRIPTS}/syncdir_win.exe" ] || [ "${SCRIPTS}/syncdir/syncdir.go" -nt "${SCRIPTS}/syncdir_win.exe" ]
then
	echo "building syncdir..."
	`cd "${SCRIPTS}/syncdir" ; go build -o ../syncdir_host`;
	`cd "${SCRIPTS}/syncdir" ; GOOS=windows GOARCH=amd64 go build -o ../syncdir_win.exe`;
fi

cd "${PROJECT}"
syncdir syncdir_host "-scan" .

PROJECT=`basename "${PROJECT}"`
ssh ${WINDOWS_BUILDER} "pushd \"\\\\vmware-host\\Shared Folders\" && scripts\win.bat $BUILDER_SHARED_FOLDER $ACTION $PROJECT"

echo ""
echo "done: win ${ACTION}"
