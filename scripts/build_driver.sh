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

	PROJECT=$1
	shift
	PROJECT_NAME=`basename $PROJECT`

	if [ ! -f "${SCRIPTS}/syncdir_host" ] || [ "${SCRIPTS}/syncdir/syncdir.go" -nt "${SCRIPTS}/syncdir_host" ]
	then
		echo "building syncdir..."
	 	`cd "${SCRIPTS}/syncdir" ; go build -o ../syncdir_host`;
	 	`cd "${SCRIPTS}/syncdir" ; GOOS=linux GOARCH=amd64 go build -o ../syncdir_linux`;
	fi
	
	syncdir syncdir_host "-scan" "$PROJECT"

	docker exec -ti builder /scripts/build_driver.sh $PROJECT_NAME $@
else
	# in container

	PROJECT_NAME=$1
	shift

	syncdir syncdir_linux '-sync' "/share/$PROJECT_NAME" "/work/$PROJECT_NAME"
	echo ""

	. /opt/rh/devtoolset-8/enable
	echo "PATH = $PATH"
	g++  --version

	cd "/work"
	mkdir -p build
	cd build

	export LLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;libcxx;libcxxabi;libunwind;lld;llvm"
	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_ENABLE_LIBXML2=0 \
		-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS} \
		-DCMAKE_INSTALL_PREFIX:PATH="/work/llvm" \
		/work/llvm_src/llvm || exit -1
	ninja || exit -1
	ninja install
	# cd /work/llvm/bin
	# ln -s clang++ c++
	# ln -s clang cc

fi
