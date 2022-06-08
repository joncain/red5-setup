#!/bin/bash

set -x

# Install Java and other required packages
#apt-get update 
#apt-get install -y openjdk-11-jdk unzip libva2 libva-drm2 libva-x11-2 libvdpau1 jsvc ntp ffmpeg 

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

server_install_file=/usr/local/red5pro-server.zip
if [[ ! -f "$server_install_file" ]]; then
  echo "ERROR: You must upload the ${server_install_file} file to /usr/local"
  exit 1
fi

# Unzip the install file
unzip -d /usr/local/red5pro $server_install_file

# Set up the service
cp /usr/local/red5pro/red5pro.service /lib/systemd/system 
chmod 644 /lib/systemd/system/red5pro.service 

systemctl daemon-reload
systemctl enable red5pro.service

# Remove unneccessary files
cd /usr/local/red5pro 
rm conf/autoscale.xml plugins/red5pro-autoscale-plugin-* plugins/red5pro-webrtc-plugin-* plugins/inspector.jar plugins/red5pro-restreamer-plugin-* plugins/red5pro-mpegts-plugin-* plugins/red5pro-socialpusher-plugin-* 
rm -rf webapps/inspector webapps/bandwidthdetection webapps/template 

#
#cp /usr/local/terraform-cloud-controller-9.3.0.jar webapps/streammanager/WEB-INF/lib 
