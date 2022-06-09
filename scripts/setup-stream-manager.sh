#!/bin/bash

source /usr/local/red5-setup/scripts/functions.sh

if [[ $RED5_VERSION = '' ]]; then
  echo -n "Please enter the Red5 version:"
  read RED5_VERSION
fi

cd /usr/local

server_file=red5-setup/files/red5pro-server.zip
if [[ ! -f "$server_file" ]]; then
  echo "ERROR: You must upload the $(pwd)/${server_file} file."
  exit 1
fi

terraform_file="red5-setup/files/terraform-cloud-controller-${RED5_VERSION}.jar"
if [[ ! -f "$terraform_file" ]]; then
  echo "ERROR: You must upload the $(pwd)/${terraform_file} file."
  exit 1
fi

# Unzip the server install file
echo "Unzipping ${server_file}"
unzip -d red5pro $server_file

# Set up the service
echo "Setting up the red5pro service"
cp red5pro/red5pro.service /lib/systemd/system 
chmod 644 /lib/systemd/system/red5pro.service 
systemctl daemon-reload
systemctl enable red5pro.service

# Copy Terraform controller
echo "Copying Terraform controller (${terraform_file})"
cp "${terraform_file}" red5pro/webapps/streammanager/WEB-INF/lib

# Remove unneccessary files
echo "Removing unneccessary files"
cd red5pro 
rm conf/autoscale.xml plugins/red5pro-autoscale-plugin-* \
   plugins/red5pro-webrtc-plugin-* plugins/inspector.jar \
   plugins/red5pro-restreamer-plugin-* plugins/red5pro-mpegts-plugin-* \
   plugins/red5pro-socialpusher-plugin-* 
rm -rf webapps/inspector webapps/bandwidthdetection webapps/template

# Interactively edit webapps/streammanager/WEB-INF/red5-web.properties file
echo "Let's edit the webapps/streammanager/WEB-INF/red5-web.properties file"
edit_config "webapps/streammanager/WEB-INF/red5-web.properties"

echo "Done"