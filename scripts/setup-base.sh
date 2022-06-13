#!/bin/bash

skip_java="${1:-false}"

if [[ $skip_java = "false" ]]; then
  echo "Installing Java and other required packages"
  apt-get update
  apt-get install -y openjdk-11-jdk unzip libva2 \
                     libva-drm2 libva-x11-2 libvdpau1 \
                     jsvc ntp ffmpeg git vim moreutils \
                     xmlstarlet
else
  echo "Skipping Java install"
fi


echo "Modifying conf files"

echo "session required pam_limits.so" >> /etc/pam.d/common-session

cat <<EOF >> /etc/sysctl.conf
fs.file-max = 1000000
kernel.pid_max = 999999
kernel.threads-max = 999999
vm.max_map_count = 1999999
EOF

cat <<EOF >> /etc/security/limits.conf
root soft nofile 1000000
root hard nofile 1000000
ubuntu soft nofile 1000000
ubuntu hard nofile 1000000
EOF

ulimit -n 1000000
sysctl -p

echo "Done"