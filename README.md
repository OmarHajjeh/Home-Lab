# 🏠 My Home Lab

![Status](https://img.shields.io/badge/Status-Active-success)
![Docker](https://img.shields.io/badge/Docker-24.0+-blue?logo=docker)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_22.04-orange?logo=ubuntu)
![Tailscale](https://img.shields.io/badge/Network-Tailscale-black?logo=tailscale)

Welcome to the documentation of my personal Home Lab journey. This repository serves as a living document of my infrastructure, configuration files, and learning progress as I build a self-hosted environment from scratch.

## 🖥️ Hardware
Starting with modest hardware to focus on software optimization and resource management.

| Component | Specification |
| :--- | :--- |
| **Model** | HP Compaq Elite 8300 SFF case |
| **CPU** | Intel Core i5 3470 |
| **RAM** | 4GB DDR3 |
| **Storage** | 256GB SSD |
| **OS** | Ubuntu Server 22.04 LTS |

## 🛠️ Software Stack
The core infrastructure is containerized using Docker, managed via Komodo for Git-sync deployments.

* **Container Engine:** Docker CE
* **Container Management:** Komodo (Git-sync deployments to `/srv`)
* **Remote Access:** Tailscale (Mesh VPN)
* **Reverse Proxy:** Traefik (automatic routing via Docker labels)
* **DNS:** Technitium DNS Server (local DNS resolver with web UI)

##  Network Architecture
The lab allows for secure remote access without opening ports on the home router.
* **External Access:** Handled via **Tailscale** Subnet Routing.
* **Internal Routing:** **Traefik** handles TLS termination and domain routing (e.g., `*.lab`) using Docker label-based auto-discovery.
* **DNS:** **Technitium DNS Server** serves as the local DNS resolver, handling wildcard rewrite rules for internal domains.

## 📦 Deployed Services
Current containers running in the production environment:

| Service | Type | Description |
| :--- | :--- | :--- |
| **Technitium DNS** | Network | Local DNS resolver with a modern web UI. |
| **Traefik** | Network | Reverse proxy with automatic HTTPS and Docker-native routing. |
| **Komodo** | Management | Git-sync container management with web UI. |
| **Homepage** | Dashboard | A modern, static dashboard to view all services at a glance. |
| **Uptime Kuma** | Monitoring | Self-hosted monitoring tool for service uptime. |
| **WhoAmI** | Utility | A tiny Go webserver for testing network routing. |

## 📁 Repository Structure

```
Home-Lab/
├── README.md
├── .gitignore
├── docs/
│   ├── 01-installation.md
│   ├── 02-networking.md
│   ├── 03-security.md
│   ├── 04-wifi-adapter.md
│   └── 05-backup.md
├── infrastructure/
│   ├── traefik/
│   │   ├── compose.yaml
│   │   ├── .env.example
│   │   └── config/
│   │       ├── traefik.yaml
│   │       ├── certs.yaml
│   │       └── dynamic/
│   │           └── middlewares.yaml
│   ├── technitium/
│   │   ├── compose.yaml
│   │   └── .env.example
│   └── komodo/
│       ├── compose.yaml
│       └── .env.example
├── apps/
│   ├── homepage/
│   │   ├── compose.yaml
│   │   └── .env.example
│   ├── uptime-kuma/
│   │   ├── compose.yaml
│   │   └── .env.example
│   └── whoami/
│       ├── compose.yaml
│       └── .env.example
└── scripts/
    ├── setup-host.sh
    ├── generate-certs.sh
    └── check-wifi.sh
```

## 📖 Documentation

| Guide | Description |
| :--- | :--- |
| [01 - Installation](docs/01-installation.md) | OS setup, Docker install, DNS stub listener fix |
| [02 - Networking](docs/02-networking.md) | Tailscale, Traefik, internal DNS |
| [03 - Security](docs/03-security.md) | SSL certificates, Traefik middlewares |
| [04 - WiFi Adapter](docs/04-wifi-adapter.md) | USB WiFi adapter setup |
| [05 - Backup](docs/05-backup.md) | Backup strategy |
| [**06 - Deployment Guide**](docs/06-deployment-guide.md) | **Full step-by-step deployment walkthrough** |

## 🚀 Quick Start

### 1. Prepare the host
```bash
bash scripts/setup-host.sh
```

### 2. Generate SSL certificates
```bash
bash scripts/generate-certs.sh
```

### 3. Deploy infrastructure (Traefik, Technitium, Komodo)
```bash
# Traefik
cd infrastructure/traefik
cp .env.example .env
cp ~/certs/star_lab.crt ./certs/
cp ~/certs/star_lab.key ./certs/
docker compose up -d

# Technitium DNS
cd ../technitium
cp .env.example .env && nano .env
docker compose up -d

# Komodo
cd ../komodo
cp .env.example .env && nano .env
docker compose up -d
```

### 4. Deploy applications
```bash
for app in apps/*/; do
  cd "$app"
  cp .env.example .env
  docker compose up -d
  cd -
done
```

### 5. Trust the Root CA on your clients
- Copy `~/certs/rootCA.pem` to client machines and install as a Trusted Root CA.
- See `docs/03-security.md` for detailed instructions.

## 🔮 Future Roadmap
* [x] Implement production-grade DNS (Technitium with built-in HA)
* [x] Make setup suitable for production environments (Komodo + Traefik + Technitium)
* [ ] Deploy this home lab setup in the cloud
* [ ] Implement automated backup strategy (Backrest)
* [ ] Set up CI/CD pipeline for automated deployments
* [ ] Test on latest Debian version

---
*Created by Omar | 2026*
