FROM jrei/systemd-ubuntu

ENV DEBIAN_FRONTEND=noninteractive

# Install Java and other required packages
RUN apt-get update
RUN apt-get install -y openjdk-11-jdk unzip libva2 libva-drm2 libva-x11-2 libvdpau1 jsvc ntp ffmpeg

COPY ./red5pro-server-us-94ff9843-9da9-49aa-828c-1eab6a0838b5.zip /usr/local/red5pro-server.zip
