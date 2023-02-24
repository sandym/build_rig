FROM --platform=linux/amd64 centos:7

ARG DEVTOOLSET=devtoolset-11

RUN echo "skip_missing_names_on_install=0" >> /etc/yum.conf && \
yum -y install centos-release-scl && \
yum -y install \
${DEVTOOLSET} \
autoconf \
automake \
file \
libtool \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum

###
# cmake
###
ARG CMAKE_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh && \
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

###
# ninja
###
ARG NINJA_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
mv ninja /usr/local/bin/ninja && \
rm -rf /tmp/ninja-*

RUN echo ". /opt/rh/${DEVTOOLSET}/enable" >> /root/.bashrc

ENV PS1='[\e[35mcentos7:amd64\e[m \W]# '
