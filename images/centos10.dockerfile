# syntax=docker/dockerfile:1
FROM quay.io/centos/centos:stream10

ADD files/rosetta_gdb_wrapper.sh /

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOT
echo "skip_missing_names_on_install=0" >> /etc/dnf/dnf.conf
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb
dnf -y install \
	autoconf \
	automake \
	file \
	gcc-toolset-15 \
	gdb \
	libtool \
	lldb \
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

RUN --mount=type=tmpfs,target=/tmp <<EOT
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -m).sh
sh cmake-${CMAKE_VERSION}-linux-$(uname -m).sh --skip-license --prefix=/usr/local
EOT

###
# ninja
###
ARG NINJA_VERSION

RUN --mount=type=tmpfs,target=/tmp <<EOT
	curl -L -O https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz
	gcc-toolset-15-env cmake -E tar zxf v${NINJA_VERSION}.tar.gz
	cd ninja-${NINJA_VERSION}
	gcc-toolset-15-env cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .
	gcc-toolset-15-env make
	gcc-toolset-15-env make install
EOT

# setup
ADD files/setup.sh /
RUN --mount=type=tmpfs,target=/tmp <<EOT
/setup.sh
rm /setup.sh
cd
echo ". /usr/lib/gcc-toolset/15-env.source" >> .bashrc
EOT

WORKDIR /

ENV PS1='[\e[35m$(source /etc/os-release ; echo ${ID}${VERSION_ID}):$(uname -m)\e[m \W]# '
