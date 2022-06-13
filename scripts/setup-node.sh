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

# Uncomment the roundTripValidator bean
# 1. Format XML without indents
# 2. strip out remaining tabs and new lines
# 3. Uncomment
# 4. Format with tab indentation
# 5. Write out the file
xmlstarlet format -n red5pro/webapps/live/WEB-INF/red5-web.xml \
| tr -d '\n\t' \
| sed 's/<!-- uncomment below for Round Trip Authentication--><!--\(.*\)--><!-- uncomment above for Round Trip Authentication-->/\1/' \
| xmlstarlet format -t \
| sponge red5pro/webapps/live/WEB-INF/red5-web.xml

cat <<EOF >> red5pro/webapps/live/WEB-INF/red5-web.properties
# Roundtrip Auth
server.validateCredentialsEndPoint=/prod/verify
server.invalidateCredentialsEndPoint=/invalidateCredentials
server.host=yechr6si61.execute-api.us-west-2.amazonaws.com
server.port=443
server.protocol=https://
EOF

# Activate autoscale
# 1. Format XML without indents
# 2. strip out remaining tabs and new lines
# 3. Uncomment
# 4. Format with tab indentation
# 5. Write out the file
xmlstarlet format -n red5pro/conf/autoscale.xml \
| tr -d '\n\t' \
| sed -e 's/<property name="active" value="false"\/>/<property name="active" value="true"\/>/' -e 's/http:\/\/0.0.0.0:5080/https:\/\/red5.vibeoffice.com/' \
| xmlstarlet format -t \
| sponge red5pro/conf/autoscale.xml

# Interactively edit red5pro/conf/cloudstorage-plugin.properties file
echo "Let's edit the red5pro/conf/cloudstorage-plugin.properties file"
edit_config "red5pro/conf/cloudstorage-plugin.properties"

# Prompt for the cluster.password
echo -n "cluster.password (changeme):"
read -r cluster_password
# Set the cluster password
sed "s/changeme/${cluster_password}/" red5pro/conf/cluster.xml | sponge red5pro/conf/cluster.xml 

echo "Done"