#!/bin/sh

function syncdir()
{
	if [ ! -f /tmp/syncdir ] || [ "${1}/syncdir.go" -nt /tmp/syncdir ]
	then
	 	`cd ${1} ; go build -o /tmp/syncdir 2> /dev/null`;
	fi
	shift
	/tmp/syncdir $@
}

if [ ! -f "/.dockerenv" ]
then
	# in host

	SCRIPTS=`dirname "$0"`
	SCRIPTS=`cd "$SCRIPTS" ; pwd`

	CONTAINER=$1
	shift
	PROJECT=$1
	shift
	PROJECT_NAME=`basename $PROJECT`

	syncdir "$SCRIPTS" "-scan" "$PROJECT"

	docker exec -ti $CONTAINER /scripts/build_driver.sh $PROJECT_NAME $@
else
	# in container

	PROJECT_NAME=$1
	shift

	syncdir "/scripts" '-sync' "/share/$PROJECT_NAME" "/work/$PROJECT_NAME"
	echo ""

	cd "/work/$PROJECT_NAME"
	./build.sh $@

fi
