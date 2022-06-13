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

# Comment out the default controller bean
# 1. Format XML without indents
# 2. strip out remaining tabs and new lines
# 3. Comment bean
# 4. Format with tab indentation
xmlstarlet format -n red5pro/webapps/streammanager/WEB-INF/applicationContext.xml | tr -d '\t\n' | sed 's/\(<bean id="apiBridge" class="com.red5pro.services.streammanager.cloud.sample.component.DummyCloudController" init-method="initialize"><\/bean>\)/<!-- \1 -->/' | xmlstarlet format -t | sponge red5pro/webapps/streammanager/WEB-INF/applicationContext.xml

# Uncomment TerraformCloudController bean
# https://www.red5pro.com/docs/installation/auto-digital-ocean/08-configure-stream-manager-instance/#import-and-activate-the-terraform-cloud-controller
# 1. Format XML without indents
# 2. strip out remaining tabs and new lines
# 3. Uncomment bean
# 4. Format with tab indentation
xmlstarlet format -n red5pro/webapps/streammanager/WEB-INF/applicationContext.xml | tr -d '\t\n' | sed 's/<!-- \(<bean id="apiBridge" class="com.red5pro.services.terraform.component.TerraformCloudController" init-method="initialize">.*<\/bean>\) -->/\1/' | xmlstarlet format -t | sponge red5pro/webapps/streammanager/WEB-INF/applicationContext.xml

# Uncomment the “CorsFilter” filter
# https://www.red5pro.com/docs/installation/stream-manager-cors/solution/
# 1. Format XML without indents
# 2. strip out remaining tabs and new lines
# 3. Uncomment
# 4. Format with tab indentation
xmlstarlet format -n red5pro/webapps/streammanager/WEB-INF/web.xml | tr -d '\n\t' | sed 's/<!-- uncomment to add CorsFilter\(.*\)-->/\1/' | xmlstarlet format | sponge red5pro/webapps/streammanager/WEB-INF/web.xml

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