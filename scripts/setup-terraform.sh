#!/bin/bash

source /usr/local/red5-setup/scripts/functions.sh

cd /usr/local
server_file=red5-setup/files/terraform-service.zip
if [[ ! -f "$server_file" ]]; then
  echo "ERROR: You must upload the $(pwd)/${server_file} file."
  exit 1
fi

# Unzip the server install file
echo "Unzipping ${server_file}"
unzip -qo $server_file

# Set up the service
echo "Setting up the red5proterraform service"
rm red5service/cloud_controller_azure.tf 
chmod +x red5service/red5terra.sh red5service/terraform 
cp red5service/red5proterraform.service /lib/systemd/system/ 
chmod 644 /lib/systemd/system/red5proterraform.service 
systemctl daemon-reload 
systemctl enable red5proterraform.service 

# Interactively edit red5service/application.properties file
echo "Let's edit the red5service/application.properties file..."
edit_config "red5service/application.properties"

# Start the service
systemctl start red5proterraform

# Provide a test link. The access token will only work if the env var
# was provided in the .env file (highly recommended).
ip=$(host myip.opendns.com resolver1.opendns.com | tail -1 | awk '{ print $(NF)}')
echo "Test link: http://${ip}:8083/terraform/test?accessToken=${r5_api_accessToken}"
echo "Done"
