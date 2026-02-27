# 01 - Installation & Base Setup

This guide documents the initial setup of the Ubuntu server, including OS configuration, Docker installation, and the deployment of Komodo for container management.

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

Ubuntu's default DNS resolver (`systemd-resolved`) listens on port 53, which conflicts with Technitium DNS Server. We must disable it.

```bash
# 1. Create a directory for the configuration override
sudo mkdir -p /etc/systemd/resolved.conf.d

# 2. Create the config file
sudo nano /etc/systemd/resolved.conf.d/technitium.conf

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

# Run Docker hello world to verify if everything work
docker run hello-world

```

## 4. Install Komodo (Management UI)

Komodo is deployed as a Docker stack to manage the rest of the lab visually.
See `infrastructure/komodo/compose.yaml` for the full stack definition.

```bash
# 1. Create the shared proxy network (required before deploying any stack)
docker network create proxy

# 2. Copy the environment template and fill in your values
cd infrastructure/komodo
cp .env.example .env
nano .env

# 3. Deploy the Komodo stack
docker compose up -d

```

### Verification

* Open your browser and go to: `https://komodo.lab`
* Create your admin account.
