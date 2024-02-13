# syntax=docker/dockerfile:1
FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN <<EOT
apt-get -y update
apt-get -y install --no-install-recommends \
	ca-certificates \
	gdb \
	g++ \
	libssl-dev \
	make \
	ninja-build \
	wget
EOT

WORKDIR /tmp

###
# cmake
###
ARG CMAKE_VERSION

RUN --mount=type=tmpfs,target=/tmp <<EOT
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local
EOT

WORKDIR /

ENV PS1='[\e[35m$(source /etc/os-release ; echo ${ID}${VERSION_ID}):$(uname -m)\e[m \W]# '
RUN <<EOT
echo "" >> /root/.bashrc
echo "PS1='$PS1'" >> /root/.bashrc
EOT
