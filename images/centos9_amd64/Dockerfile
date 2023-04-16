FROM --platform=linux/amd64 quay.io/centos/centos:stream9

RUN echo "skip_missing_names_on_install=0" >> /etc/dnf/dnf.conf && \
dnf install -y dnf-plugins-core && \
dnf config-manager --set-enabled crb && \
dnf -y install \
autoconf \
automake \
file \
gcc-toolset-12 \
libtool \
openssl-devel \
procps \
python \
which && \
dnf clean all && rm -rf /var/cache/dnf

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
curl -L -O https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz && \
. /opt/rh/gcc-toolset-12/enable && \
cmake -E tar zxf v${NINJA_VERSION}.tar.gz && \
cd ninja-${NINJA_VERSION} && \
cmake -DCMAKE_BUILD_TYPE=Release . && \
which make && \
python -c 'import pty; pty.spawn("make")' && \
python -c 'import pty; pty.spawn("make install")' && \
rm -rf /tmp/v${NINJA_VERSION}.tar.gz /tmp/ninja-*

ENV PS1='[\e[35mcentos9:amd64\e[m \W]# '
