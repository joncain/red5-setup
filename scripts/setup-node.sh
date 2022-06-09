#!/bin/bash

source /usr/local/red5-setup/scripts/functions.sh

cd /usr/local

server_file=red5-setup/files/red5pro-server.zip
if [[ ! -f "$server_file" ]]; then
  echo "ERROR: You must upload the $(pwd)/${server_file} file."
  exit 1
fi

# Unzip the server install file
echo "Unzipping ${server_file}"
unzip -d red5pro $server_file

# Set up the service
cp /usr/local/red5pro/red5pro.service /lib/systemd/system/
chmod 644 /lib/systemd/system/red5pro.service
systemctl daemon-reload
systemctl enable red5pro.service

cat <<EOF >> red5pro/webapps/live/WEB-INF/red5-web.properties
# Roundtrip Auth
server.validateCredentialsEndPoint=/prod/verify
server.invalidateCredentialsEndPoint=/invalidateCredentials
server.host=yechr6si61.execute-api.us-west-2.amazonaws.com
server.port=443
server.protocol=https://
EOF

# Interactively edit red5pro/conf/cloudstorage-plugin.properties file
echo "Let's edit the red5pro/conf/cloudstorage-plugin.properties file"
edit_config "red5pro/conf/cloudstorage-plugin.properties"

echo "Done"