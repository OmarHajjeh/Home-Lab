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
The core infrastructure is containerized using Docker, managed via Portainer for ease of orchestration.

* **Container Engine:** Docker CE
* **Orchestration:** Portainer
* **Remote Access:** Tailscale (Mesh VPN)
* **Reverse Proxy:** Nginx Proxy Manager

## 🌐 Network Architecture
The lab allows for secure remote access without opening ports on the home router.
* **External Access:** Handled via **Tailscale** Subnet Routing.
* **Internal Routing:** **Nginx Proxy Manager** handles SSL termination and domain routing (e.g., `*.lab`).
* **DNS:** **AdGuard Home** serves as the local DNS resolver, handling rewrite rules for internal domains.

## 📦 Deployed Services
Current containers running in the production environment:

| Service | Type | Description |
| :--- | :--- | :--- |
| **AdGuard Home** | Network | Network-wide ad blocking and local DNS resolution. |
| **Nginx Proxy Manager** | Network | Reverse proxy to route traffic to containers. |
| **Portainer** | Management | Web UI for managing Docker containers and stacks. |
| **Homepage** | Dashboard | A modern, static dashboard to view all services at a glance. |
| **Uptime Kuma** | Monitoring | Self-hosted monitoring tool for service uptime. |
| **WhoAmI** | Utility | A tiny Go webserver for testing network routing. |

## 🚀 Future Roadmap
* [ ] Implement high availability for DNS (Secondary AdGuard).
* [ ] Automate backups using Duplicati.
* [ ] Implement local https.
* [ ] Make this setup suitable for production environments.
* [ ] Try to deploy this exact home lab setup in the cloud.

---
*Created by Omar | 2026*
