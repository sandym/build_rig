FROM ubuntu:20.04

ENV WINEARCH=win64 \
WINEDEBUG=-all,err \ 
DISPLAY=:0.0 \
WINE_MONO_VERSION=5.0.0 \
WINE_GECKO_VERSION=2.47.1

ARG DEBIAN_FRONTEND=noninteractive

RUN export DEBIAN_FRONTEND="noninteractive" && \
apt-get update && \
apt-get install -y \
ca-certificates \
curl \
gnupg2 \
software-properties-common \
unzip \
winbind && \
dpkg --add-architecture i386 && \
curl -L https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/winehq.key && \
apt-key add /etc/apt/winehq.key && \
apt-get update && \
apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' && \
apt update && \
apt-get upgrade -y && \
apt install -y winehq-stable && \
curl -L https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -o /usr/local/bin/winetricks && \
chmod +rx /usr/local/bin/winetricks && \
apt-get autoclean && \
apt-get clean && \
apt-get autoremove --purge && \
rm -rf /var/apt/cache/* && \
rm -rf /tmp/*

#  && \
# mkdir -p /home/wine && \
# useradd --system -d /home/wine --shell /bin/bash --uid 1000 --gid root wine && \
# chown -R wine /home/wine

# USER wine

WORKDIR /root

RUN mkdir -p /root/.cache/wine && \
curl -L https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi \
	-o /root/.cache/wine/wine-mono-${WINE_MONO_VERSION}.msi && \
curl -L https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86.msi \
	-o /root/.cache/wine/wine-gecko-${WINE_GECKO_VERSION}-x86.msi && \
curl -L https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86_64.msi \
	-o /root/.cache/wine/wine-gecko-${WINE_GECKO_VERSION}-x86_64.msi && \
wine wineboot --init && \
while pgrep wineserver > /dev/null; do sleep 1; done && \
winetricks --unattended dotnet45 ; \
winetricks --unattended win10 && \
rm -rf /root/.cache

ENTRYPOINT [ "/bin/bash", "-c", "wine64 cmd" ]


# apt install -y --install-recommends winehq-stable

# RUN apt-get install -y \
#         p7zip \
#         zenity \
#         cabextract \
#         binutils \
