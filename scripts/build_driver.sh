#!/bin/sh

function syncdir()
{
	if [ "${1}/syncdir.go" -nt /tmp/syncdir ]
	then
	 	`cd ${1} ; go build -o /tmp/syncdir`;
	fi
	shift
	/tmp/syncdir $@
	echo ""
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
	
	syncdir "$SCRIPTS" "-scan" "$PROJECT"

	# docker exec -ti $CONTAINER /scripts/build_driver.pl $@
else
	# in container

	echo "$SCRIPTS"
	# my $projectName = basename $project;
	syncdir "/scripts" '-sync' "/share/$projectName" "/work/$projectName"

	cd "/work/$projectName"
	./build.sh $@

fi
