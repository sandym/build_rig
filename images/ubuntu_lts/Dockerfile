FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
apt-get -y install wget g++ gdb libssl-dev make time && \
apt-get autoclean && \
apt-get clean && \
apt-get autoremove --purge && \
rm -rf /var/apt/cache/* && \
rm -rf /tmp/*

ARG CMAKE_VERSION

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION

RUN cd /usr/local/bin && \
wget https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip && \
ln -s /usr/bin/gdb

ENV PS1='[\e[35mubuntu_lts\e[m \W]# '
RUN echo "" >> /root/.bashrc && \
echo "PS1='$PS1'" >> /root/.bashrc
