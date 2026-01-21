
# ZeroByte Docker Backup Documentation (2026)

## 0. Infrastructure Setup

### Host Preparation
Ensure the local backup directory exists and has the correct permissions on the host machine:

```bash
mkdir -p /home/omar/backups
sudo chown -R $USER:$USER /home/omar/backups
sudo chmod -R 755 /home/omar/backups

```

## 1. Overview

This configuration provides automated, daily, encrypted backups of all Docker container data, Portainer configurations, and named volumes. It maps the host's Docker directory directly into ZeroByte as a **read-only source** to ensure the security of the live system.

## 2. Portainer Stack Configuration

Deploy the following YAML in your Portainer Stacks. This configuration ensures ZeroByte has the necessary system permissions (`SYS_ADMIN`) and access to the FUSE device required by Restic for advanced mounting.

```yaml
services:
  zerobyte:
    image: ghcr.io/nicotsx/zerobyte:latest
    container_name: zerobyte
    restart: unless-stopped
    cap_add:
      - SYS_ADMIN
    ports:
      - "4096:4096"
    devices:
      - /dev/fuse:/dev/fuse
    environment:
      - TZ=Asia/Beirut
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/lib/zerobyte:/var/lib/zerobyte        # Internal app data
      - /var/lib/docker:/docker_data:ro            # Source: All Docker/Portainer data
      - /home/omar/backups:/my_local_backups       # Destination: Encrypted Vault

```

## 3. Post-Deployment Setup (Web UI)

### A. Volume Configuration
Access the WebUi by entering machineip:4096
Create an account 
Save the pass given this is required to decrypt your data; do not lose it.

1. Navigate to the **Volumes** tab.
2. Click **Create Volume**.
3. **Name:** `Docker_System_Data`
4. **Path:** `/docker_data`
5. **Type:** Directory

### B. Repository Configuration (The Vault)

1. Navigate to the **Repositories** tab.
2. Click **Create Repository**.
3. **Type:** Local Directory
4. **Path:** `/my_local_backups`



### C. Backup Job Configuration

* **Schedule:** `0 0 10 * * *` (10:00 AM Daily)
* **Source Volume:** `Docker_System_Data`
* **Backup Paths:** Leave empty (Backs up everything in `/docker_data`).
* **Exclude Patterns:** (One per line to skip temporary/junk files)

```text
/docker_data/tmp/**
/docker_data/buildkit/**
/docker_data/containers/**/mounts/**
```

### D. Retention Policy (GFS)

To optimize disk space while maintaining history, use the **Grandfather-Father-Son** strategy:

* **Keep Most Recent:** `7` (Daily recovery for the last week)
* **Keep Weekly:** `4` (One snapshot for each of the last 4 weeks)
* **Keep Monthly:** `6` (History for the last half-year)
* **Keep Yearly:** `1` (Long-term archive)
* **Stay on one file system:** `Enabled`
