#!/bin/sh

cd

RC_FILE=".bashrc"

if [ "$(souce /etc/os_release ; echo ${ID})" = "alpine" ]
then
	RC_FILE=".ashrc"
fi

echo "alias dir='ls -alv --color=auto'" >> ${RC_FILE}
echo "function cdd() { cd $* ; dir ; }" >> ${RC_FILE}

if [ "${RC_FILE}" = ".bashrc" ]
then
	echo "tabs 4" >> ${RC_FILE}
fi
