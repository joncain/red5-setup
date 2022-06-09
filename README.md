# Red 5 Ecosystem Setup (Digital Ocean)

This is a document to pull together the Red 5 documentation that is specifically needed for our setup. This document was created using Red 5 version 9.3.0.

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/overview/) for more information.

## [Download](https://account.red5pro.com/downloads) Latest Install Files

- Red 5 Pro Server
- Terraform Autoscale controller 9.3.0 for Digital Ocean
- Terraform Binary and Configuration Files for Terraform Server for Digital Ocean

## Load Balancer

Create a load balancer in Digital Ocean. See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/09-optional-load-balance-stream-managers/) for more information.

- Size: Small
- Region: sfo3
- VPC: Default
- Droplets: None
- Forwarding Rules
  - HTTP 80 -> HTTP 5080
  - HTTPS 443 -> HTTP 5080
    - Cert: wildcard.vibeoffice.com
- Algorithm: Round Robin
- Health checks: <http://0.0.0.0:5080/>
- Sticky sessions: Off
- SSL: No redirect
- Proxy Protocol: Disabled
- Backend Keepalive: Disabled
- Name: red5pro

## DNS

Set up the host name (red5.vibeoffice.com) in AWS’s Route 53.

Hosted Zones

- vibeoffice.com
  - Create Record
    - Simple Routing
    - Define simple record
      - Record name: red5
      - Record type: A
      - Value: IP address of the load balancer
      - TTL: 300

## Create Firewalls

### red5-sm-inbound-ports

- Inbound Ports
  - TCP
    - 22, 1935, 5080, 6262, 8081, 8083, 8554
  - UDP
    - 40000 - 65535

### red5-terraform

- Inbound Ports
  - TCP
    - 22, 8083

## Create MySQL Instance

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/06-create-sql-database/) for more information.

## Create Base Droplet

This droplet will eventually become the stream manager. In this initial setup we will configure
a base image that will be the starting point for all of our droplets. See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/04-create-an-optimized-disk-image/)
for more information.

### Droplet Properties

- Distribution: Ubuntu 20.04 (LTS) x64
- Plan: CPU Optimized; 4 GB / 2 CPU / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Hostname: red5pro-base

### Configure Droplet

- SSH to droplet and run the following commands

```bash
git clone https://github.com/joncain/red5-setup.git /usr/local/red5-setup 
```

```bash
/usr/local/red5-setup/scripts/setup-base.sh 
```

- SCP install files to the instance

```bash
scp ./terraform-service.zip ./red5pro-server.zip ./terraform-cloud-controller-9.3.0.jar root@<droplet-ip-address>:/usr/local/red5-setup/files/ 
```

- Turn off Droplet

### Create Snapshot

Create a Snapshot of the droplet and name it: red5pro-base

## Create Terraform Droplet

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/05-create-sm-and-terraform-instances/) for more information.

### Droplet Properties

- Snapshot: red5pro-base
- Plan: CPU Optimized; 4 GB / 2 CPUs / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Name: red5pro-terraform-93

### Configure Terraform

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/07-configure-terraform-server/) for more information.

- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-terraform.sh 
```

- Start the service

```bash
systemctl start red5proterraform 
```

- Test the service: [http://droplet-ip-address:8083/terraform/test?accessToken=<api.accessToken>]()

## Stream Manager

This is the red5pro-base droplet that was created in a previous step. See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/08-configure-stream-manager-instance/) for more information.

### Activate Droplet

- Add the droplet to the red5-sm-inbound-ports firewall
- Turn on droplet

### Configure Stream Manager

- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-stream-manager.sh 
```

- Edit `/usr/local/red5pro/webapps/streammanager/WEB-INF/applicationContext.xml`

  - Locate the Terraform Cloud controller bean and uncomment it
  - Comment out the default controller bean
  - See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/08-configure-stream-manager-instance/#import-and-activate-the-terraform-cloud-controller) for more information

- Edit `webapps/streammanager/WEB-INF/web.xml`
  - Uncomment the “CorsFilter” filter
  - See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/stream-manager-cors/solution) for more information.

- Add the droplet as a trusted source in the MySQL server

- Start the service

```bash
systemctl start red5pro 
```

- Test the service: [http://droplet-ip-address:5080]()

## Create Node Droplet

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/10-prepare-node-droplet/) for more information.

### Droplet Properties

- Snapshot: red5pro-base
- Plan: CPU Optimized; 4 GB / 2 CPUs / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Name: red5pro-node-93

### Configure Droplet

- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-node.sh 
```

- Edit `red5pro/conf/autoscale.xml`
  - See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/10-prepare-node-droplet/#configure-autoscaling-on-the-instance) for details

- Edit `red5pro/conf/cluster.xml`
  - See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/10-prepare-node-droplet/#set-a-unique-cluster-password) for details

- Edit `red5pro/webapps/live/WEB-INF/red5-web.xml`
  - uncomment the “roundTripValidator” bean

- Edit `red5pro/conf/red5-common.xml`
  - Set the "writerPostProcessors" value.

```
<bean id="flv.impl" class="org.red5.io.flv.impl.FLV"> 
  <property name="cache"> 
    <ref bean="object.cache"/> 
  </property> 
  <property name="writerPostProcessors"> 
    <set> 
      <value>com.red5pro.media.processor.DOUploaderPostProcessor</value> 
    </set> 
  </property> 
</bean> 
```

- Edit `webapps/live/WEB-INF/red5-web.xml`
  - Uncomment the "streamFilenameGenerator" line.

```bash
<bean id="streamFilenameGenerator" class="com.red5pro.media.storage.digitalocean.DOFilenameGenerator"/> 
```

- Start the service

```bash
systemctl start red5pro 
```

- Test the service: [http://droplet-ip-address:5080]()

- Turn off droplet

### Create Node Image

See the [Red 5 documentation](https://www.red5pro.com/docs/autoscale/digital-ocean/11-create-node-image/) for more information.
