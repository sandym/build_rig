FROM ubuntu:21.10

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
apt-get -y install wget clang g++ gdb libssl-dev make ninja-build time && \
apt-get autoclean && \
apt-get clean && \
apt-get autoremove --purge && \
rm -rf /var/apt/cache/* && \
rm -rf /tmp/*

ARG CMAKE_VERSION

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh && \
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ENV PS1='[\e[35mubuntu\e[m \W]# '
RUN echo "" >> /root/.bashrc && \
echo "PS1='$PS1'" >> /root/.bashrc
