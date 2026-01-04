FROM ubuntu:24.04

USER root

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Install necessary packages for RoonServer and audio/network support
RUN apt-get update -q && \
    apt-get install --no-install-recommends -y -q \
        ca-certificates apt-utils ffmpeg libasound2-dev cifs-utils alsa \
        usbutils udev curl wget bzip2 lbzip2 tzdata locales && \
    apt-get autoremove -y -q && \
    apt-get clean -y -q && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG en_US.utf8
ENV TZ=Asia/Seoul
ENV HOME=/opt/RoonServer
ENV ROON_DATAROOT=/var/roon

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Download and extract RoonServer to /opt
WORKDIR /opt
RUN wget -nv https://download.roonlabs.com/builds/RoonServer_linuxx64.tar.bz2 && \
    bzip2 -d RoonServer_linuxx64.tar.bz2 && \
    tar -xvf RoonServer_linuxx64.tar && \
    rm RoonServer_linuxx64.tar && \
    chmod +x /opt/RoonServer/start.sh

# After RoonServer is installed, remove apt and tools
RUN apt-get update -q || true && \
    apt-get purge -y --auto-remove \
        curl wget apt-utils \
        openssh-client openssh-server \
        netcat-openbsd net-tools \
        iputils-ping telnet traceroute || true && \
    rm -f /usr/bin/apt /usr/bin/apt-get /usr/bin/apt-cache /usr/bin/apt-config && \
    rm -rf /etc/apt /var/lib/apt /var/cache/apt /var/lib/apt/lists/*

# Create directory
RUN mkdir -p /var/roon

# Declare mountable volumes
VOLUME ["/opt/RoonServer", "/var/roon"]

# Set working directory
WORKDIR /opt/RoonServer

# Expose RoonServer-related ports for documentation and auto-mapping
# Core discovery (multicast)
EXPOSE 9003/udp
# Roon Display web UI
EXPOSE 9100/tcp
# RAATServer communication
EXPOSE 9100-9200/tcp
# Cloud events (websocket-like traffic)
EXPOSE 9200/tcp
# Chromecast device communication
EXPOSE 30000-30010/tcp
# Unofficial but observed ports for Roon Core <-> endpoint traffic
EXPOSE 9330-9339/tcp
EXPOSE 9001-9002/tcp
EXPOSE 49863/tcp
EXPOSE 52667/tcp
EXPOSE 52709/tcp
EXPOSE 63098-63100/tcp

# Default command to launch RoonServer
CMD ["/opt/RoonServer/start.sh"]
