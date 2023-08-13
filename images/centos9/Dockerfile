# syntax=docker/dockerfile:1
FROM quay.io/centos/centos:stream9

ARG TOOLSET=gcc-toolset-13

RUN --mount=type=cache,target=/var/cache/dnf <<EOT
echo "skip_missing_names_on_install=0" >> /etc/dnf/dnf.conf
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb
dnf -y install \
	autoconf \
	automake \
	file \
	${TOOLSET} \
	libtool \
	openssl-devel \
	procps \
	python \
	which
EOT

WORKDIR /tmp

###
# cmake
###
ARG CMAKE_VERSION

RUN --mount=type=cache,target=/tmp <<EOT
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local
EOT

###
# ninja
###
ARG NINJA_VERSION

RUN --mount=type=cache,target=/tmp <<EOT
curl -L -O https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz
. /opt/rh/${TOOLSET}/enable
cmake -E tar zxf v${NINJA_VERSION}.tar.gz
cd ninja-${NINJA_VERSION}
cmake -DCMAKE_BUILD_TYPE=Release .
make -j$(nproc)
make install
EOT

WORKDIR /

ENV PS1='[\e[35mcentos9:$(uname -m)\e[m \W]# '
