FROM quay.io/centos/centos:stream9

RUN echo "skip_missing_names_on_install=0" >> /etc/yum.conf && \
yum -y install \
file \
gcc-c++ \
gdb \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum

ARG CMAKE_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh && \
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz && \
cmake -E tar zxf v${NINJA_VERSION}.tar.gz && \
cd ninja-${NINJA_VERSION} && \
cmake -DCMAKE_BUILD_TYPE=Release . && \
make -j$(nproc) && \
make install

ENV PS1='[\e[35mcentos9\e[m \W]# '
