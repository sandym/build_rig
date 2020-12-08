FROM centos:7

RUN yum -y update && \
yum -y install centos-release-scl && \
yum -y install \
devtoolset-8-gcc-c++ \
devtoolset-9 \
openssl-devel \
time \
which && \
yum clean all && rm -rf /var/cache/yum && \
cd /usr/local/bin && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/make && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gdb && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gcore && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gstack

ARG CMAKE_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION

RUN cd /usr/local/bin && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip
