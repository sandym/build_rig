# syntax=docker/dockerfile:1
FROM alpine

RUN <<EOT
apk add --no-cache \
	clang \
	g++ \
	gdb \
	make \
	linux-headers \
	openssl-dev
EOT

WORKDIR /tmp

###
# cmake
###
ARG CMAKE_VERSION

RUN --mount=type=tmpfs,target=/tmp <<EOT
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
tar -zxf cmake-${CMAKE_VERSION}.tar.gz
cd cmake-${CMAKE_VERSION}
./bootstrap
make -j$(nproc)
make install
EOT

###
# ninja
###
ARG NINJA_VERSION

RUN --mount=type=tmpfs,target=/tmp <<EOT
	wget https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz
	cmake -E tar zxf v${NINJA_VERSION}.tar.gz
	cd ninja-${NINJA_VERSION}
	cmake -DCMAKE_BUILD_TYPE=Release .
	make
	make install
EOT

WORKDIR /

ENV PS1='[\e[35m$(source /etc/os-release ; echo ${ID}):$(uname -m)\e[m \W]# '
