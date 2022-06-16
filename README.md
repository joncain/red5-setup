# Red 5 Ecosystem Setup (Digital Ocean)

This is a document to pull together the Red 5 documentation that is specifically needed for our setup.

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/installation/do-install/) for more information.

## [Download](https://account.red5pro.com/downloads) Latest Install Files

- Red 5 Pro Server
- Terraform Autoscale controller x.x.x for Digital Ocean
- Terraform Binary and Configuration Files for Terraform Server for Digital Ocean

## Configuration Values

You will need a copy of the Digital Ocean Checklist provided by Red5 to obtain the configuration values. The key names in the configuration files do not neccessarily match the Checklist document.

### Key map

|Config Key|Document Key|
|---|---|
|api.accessToken|api.accessToken (terra.token)|
|cloud.do_api_token|Token value|
|cloud.do_ssh_key_name|SSH KeyPair Name|
|cluster.password|Red5 Pro cluster password|
|terra.port|server.port|
|terra.token|api.accessToken (terra.token)|
|serverapi.accessToken|API token|
|rest.administratorToken|API token|
|proxy.enabled|proxy.enabled|

### .env

**IMPORTANT NOTE:** Set these values in the `scripts/.env` file to make your life easier. The interactive script will pull values from that file.

## Load Balancer

Create a load balancer in Digital Ocean. See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/09-optional-load-balance-stream-managers/#create-load-balancer) for more information.

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

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/installation/do-install/#optional---firewall) for more information.

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

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/06-create-sql-database/) for more information.

## Create Base Droplet

This droplet will eventually become the stream manager. In this initial setup we will configure
a base image that will be the starting point for all of our droplets. See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/04-create-an-optimized-disk-image/)
for more information.

### Droplet Properties

- Distribution: Ubuntu 20.04 (LTS) x64
- Plan: CPU Optimized; 4 GB / 2 CPU / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Hostname: red5pro-base-x.x.x

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
scp ./terraform-service.zip ./red5pro-server.zip ./terraform-cloud-controller-x.x.x.jar root@<droplet-ip-address>:/usr/local/red5-setup/files/ 
```

- Add configuration values to the `/usr/local/red5-setup/scripts/.env` file. See the [Configuration Values](#configuration-values) section for details.

- Turn off Droplet

### Create Snapshot

Create a Snapshot of the droplet and name it: red5pro-base-x.x.x

## Create Terraform Droplet

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/05-create-sm-and-terraform-instances/) for more information.

### Droplet Properties

- Snapshot: red5pro-base-x.x.x
- Plan: CPU Optimized; 4 GB / 2 CPUs / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Name: red5pro-terraform-x.x.x

### Configure Terraform

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/07-configure-terraform-server/) for more information.

- Add droplet to the red5-terraform firewall
- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-terraform.sh 
```

- Test the service: [http://droplet-ip-address:8083/terraform/test?accessToken=<api.accessToken>](http://droplet-ip-address:8083/terraform/test?accessToken=<api.accessToken>)

## Stream Manager

This is the red5pro-base droplet that was created in a previous step. See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/08-configure-stream-manager-instance/) for more information.

### Activate Droplet

- Rename the droplet to: red5pro-streammanager-x.x.x
- Add the droplet to the red5-sm-inbound-ports firewall
- Add the droplet as a trusted source in the MySQL server
- Turn on droplet

### Configure Stream Manager

- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-stream-manager.sh 
```

- Test the service: [http://droplet-ip-address:5080](http://droplet-ip-address:5080)

## Create Node Droplet

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/10-prepare-node-droplet/) for more information.

### Droplet Properties

- Snapshot: red5pro-base-x.x.x
- Plan: CPU Optimized; 4 GB / 2 CPUs / 25 GB Disk
- Region: sfo3
- VPC: default-sfo3
- SSH Key: red5pro-icentris
- Name: red5pro-node-x.x.x

### Configure Droplet

- SSH to the server and run the following commands. This script is interactive and will prompt you for configuration values.

```bash
/usr/local/red5-setup/scripts/setup-node.sh 
```

- Test the service: [http://droplet-ip-address:5080](http://droplet-ip-address:5080)

- Turn off droplet

### Create Node Image

See the [Red 5 documentation](https://www.red5pro.com/docs/installation/auto-digital-ocean/11-create-node-image/) for more information.

### Destroy the droplet

This node droplet can now be destroyed.

## Create Scale Policy

Use the [red5-cli](https://github.com/iCentris/red5-cli) to create a scale policy. This is only required for a fresh install.

```bash
red5 create-policy
```

## Create Launch Config

Use the [red5-cli](https://github.com/iCentris/red5-cli) to create a launch config. If the Red5 version has changed, you will need to adjust the request template.

```bash
red5 create-config
```

## Create Node Group

Use the [red5-cli](https://github.com/iCentris/red5-cli) to create a node group. If the Red5 version has changed, you will need to adjust the request template.

```bash
red5 create-group
```

## Launch Origin

Use the [red5-cli](https://github.com/iCentris/red5-cli) to launch.

```bash
red5 launch-origin
```

## Add Stream Manager to Load Balancer

After adding the stream manager droplet to the load balancer, and verifying the load balancer is up. Test the actual url for the system: <https://red5.vibeoffice.com>
