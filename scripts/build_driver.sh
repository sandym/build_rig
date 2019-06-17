#!/bin/sh

SCRIPTS=`dirname "$0"`
SCRIPTS=`cd "${SCRIPTS}" ; pwd`

function syncdir()
{
	SYNCDIR=$1
	shift
	"${SCRIPTS}/$SYNCDIR" $@
}

if [ ! -f "/.dockerenv" ]
then
	# in host

	CONTAINER=$1
	shift
	PROJECT=$1
	shift
	PROJECT_NAME=`basename $PROJECT`

	if [ ! -f "${SCRIPTS}/syncdir_host" ] || [ "${SCRIPTS}/syncdir/syncdir.go" -nt "${SCRIPTS}/syncdir_host" ]
	then
	 	`cd "${SCRIPTS}/syncdir" ; GOOS=linux GOARCH=amd64 go build -o ../syncdir_linux`;
	 	`cd "${SCRIPTS}/syncdir" ; go build -o ../syncdir_host`;
	fi
	
	syncdir syncdir_host "-scan" "$PROJECT"

	docker exec -ti $CONTAINER /scripts/build_driver.sh $PROJECT_NAME $@
else
	# in container

	PROJECT_NAME=$1
	shift

	syncdir syncdir_linux '-sync' "/share/$PROJECT_NAME" "/work/$PROJECT_NAME"
	echo ""

	cd "/work/$PROJECT_NAME"

	# 
	./build.sh $@

fi
