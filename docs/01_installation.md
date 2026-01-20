# 01 - Installation & Base Setup

This guide documents the initial setup of the Ubuntu server, including OS configuration, Docker installation, and the deployment of Portainer for container management.

## 1. Prerequisites
* **OS:** Ubuntu 22.04 LTS (Clean Install).
* **Network:** (set up static IP).

## 2. OS Preparation
Before installing Docker, update the system and install essential tools.

```bash
# Update repositories and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install utility tools
sudo apt install -y curl wget git nano net-tools

```

### 2.1 Fix DNS Stub Conflict (Ubuntu Specific)

Ubuntu's default DNS resolver (`systemd-resolved`) listens on port 53, which conflicts with AdGuard Home. We must disable it.

```bash
# 1. Create a directory for the configuration override
sudo mkdir -p /etc/systemd/resolved.conf.d

# 2. Create the config file
sudo nano /etc/systemd/resolved.conf.d/adguardhome.conf

```

Paste the following into the file:

```ini
[Resolve]
DNS=127.0.0.1
DNSStubListener=no

```

Apply the changes:

```bash
# Backup original resolv.conf
sudo mv /etc/resolv.conf /etc/resolv.conf.backup

# Link the systemd-resolved file
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Restart the service
sudo systemctl restart systemd-resolved

```

## 3. Install Docker Engine

We use the official installation script for convenience.

```bash
# Download and run the install script
curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh
sudo sh get-docker.sh

# Add current user to the docker group (avoids using sudo)
sudo usermod -aG docker $USER

# Activate changes (or logout and login)
newgrp docker

# Run Docker hello world to verify if everyting work
docker run hello-world

```

## 4. Install Portainer (Management UI)

Portainer is deployed as a Docker container to manage the rest of the lab visually.

```bash
# 1. Create a volume for Portainer data
docker volume create portainer_data

# 2. Deploy the Portainer container
docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

```

### Verification

* Open your browser and go to: `https://<YOUR-SERVER-IP>:9443`
* Create your admin account.
