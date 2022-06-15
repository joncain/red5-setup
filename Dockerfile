FROM jrei/systemd-ubuntu

ENV DEBIAN_FRONTEND=noninteractive

# Install Java and other required packages
RUN apt-get update
RUN apt-get install -y openjdk-11-jdk unzip libva2 \
                       libva-drm2 libva-x11-2 libvdpau1 \
                       jsvc ntp ffmpeg git vim moreutils \
                       xmlstarlet host

WORKDIR /usr/local
