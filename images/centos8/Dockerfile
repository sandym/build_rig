FROM centos:8

RUN yum -y update && \
yum -y install \
curl \
gcc-c++ \
gcc-toolset-9-gcc-c++ \
gcc-toolset-9-gdb \
gcc-toolset-9-gcc-gdb-plugin \
gcc-toolset-9-make \
git \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum && \
cd /usr/local/bin && \
ln -s /opt/rh/gcc-toolset-9/root/usr/bin/make && \
ln -s /opt/rh/gcc-toolset-9/root/usr/bin/gdb

ARG CMAKE_VERSION=3.17.2

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
tar -zxf cmake-${CMAKE_VERSION}.tar.gz && \
cd cmake-${CMAKE_VERSION} && \
./bootstrap && \
make -j$(nproc) && \
make install  && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION=v1.10.0

RUN cd /usr/local/bin && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip

CMD ["sleep","infinity"]
