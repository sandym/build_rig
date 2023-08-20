# syntax=docker/dockerfile:1
FROM alpine

RUN <<EOT
apk add --no-cache \
	clang \
	g++ \
	gdb \
	make \
	ninja \
	linux-headers \
	openssl-dev
EOT

WORKDIR /tmp

###
# cmake
###
ARG CMAKE_VERSION

RUN --mount=type=cache,target=/tmp <<EOT
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
tar -zxf cmake-${CMAKE_VERSION}.tar.gz
cd cmake-${CMAKE_VERSION}
./bootstrap
make -j$(nproc)
make install
EOT

WORKDIR /

ENV PS1='[\e[35malpine:$(uname -m)\e[m \W]# '
