# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 quay.io/centos/centos:stream9

RUN --mount=type=cache,target=/var/cache/dnf <<EOT
echo "skip_missing_names_on_install=0" >> /etc/dnf/dnf.conf
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb
dnf -y install \
	autoconf \
	automake \
	file \
	gcc-toolset-12 \
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
curl -L -O https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip
cmake -E tar zxf ninja-linux.zip
cp ninja /usr/local/bin/.
EOT

WORKDIR /

ENV PS1='[\e[35mcentos9:amd64\e[m \W]# '
