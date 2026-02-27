
# 05 - Backup Strategy

This document describes the backup approach for the Home Lab. The goal is to implement automated, encrypted backups of all container data using **Backrest** (a web UI for Restic).

> **Status:** Backup strategy is currently being evaluated. Backrest has been selected as the target solution and will be integrated in a future update.

## 1. Overview

The backup strategy will cover:
- Docker named volumes (application data)
- Compose configuration files from `/srv`
- SSL certificates

## 2. Planned: Backrest

[Backrest](https://github.com/garethgeorge/backrest) is a web-accessible interface for [Restic](https://restic.net/), a fast, encrypted backup program.

### Planned Stack Configuration

```yaml
services:
  backrest:
    image: garethgeorge/backrest:latest
    container_name: backrest
    restart: unless-stopped
    volumes:
      - ./data:/data                        # Backrest config and metadata
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /srv:/srv:ro                        # Source: all Komodo-managed stacks
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backrest.rule=Host(`backup.lab`)"
      - "traefik.http.routers.backrest.entrypoints=websecure"
      - "traefik.http.routers.backrest.tls=true"
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## 3. Retention Policy (GFS)

To optimize disk space while maintaining history, the **Grandfather-Father-Son** strategy will be used:

* **Keep Most Recent:** `7` (Daily recovery for the last week)
* **Keep Weekly:** `4` (One snapshot for each of the last 4 weeks)
* **Keep Monthly:** `6` (History for the last half-year)
* **Keep Yearly:** `1` (Long-term archive)

## 4. Previous Solution (ZeroByte)

The previous backup tool was ZeroByte (a Restic web UI). It has been replaced with Backrest as the new target solution.
