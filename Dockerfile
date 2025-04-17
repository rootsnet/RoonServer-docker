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
RUN apt update -q && \
    apt install --no-install-recommends -y -q \
        ca-certificates apt-utils ffmpeg libasound2-dev cifs-utils alsa \
        usbutils udev curl wget bzip2 tzdata && \
    apt autoremove -y -q && \
    apt clean -y -q && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV TZ=Asia/Seoul
ENV HOME=/opt/RoonServer
ENV ROON_DATAROOT=/var/roon

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Copy pre-extracted RoonServer directory
COPY RoonServer /opt/RoonServer

# Make start script executable
RUN chmod +x /opt/RoonServer/start.sh

# Create data directory
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
CMD ["./start.sh"]

