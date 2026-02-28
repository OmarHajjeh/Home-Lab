# 06 - Full Deployment Guide

This guide covers the complete, step-by-step process to deploy the entire home lab stack from scratch — from host preparation through post-deployment configuration.

## Prerequisites

Before you begin, ensure the following are in place:

- **Port 53 must be free.** Ubuntu's `systemd-resolved` DNS stub listener occupies port 53 by default, which conflicts with Technitium DNS. Disable it first — see [Section 2.1 of the Installation Guide](01-installation.md#21-fix-dns-stub-conflict-ubuntu-specific).
- **Docker must be installed.** See [Section 3 of the Installation Guide](01-installation.md#3-install-docker-engine).
- **The repo must be cloned to `/srv/home-lab`:**
  ```bash
  sudo mkdir -p /srv
  git clone https://github.com/OmarHajjeh/Home-Lab.git /srv/home-lab
  cd /srv/home-lab
  ```

---

## 1. Environment Files Setup

> ⚠️ **IMPORTANT: Docker `.env` files do NOT support inline comments.**
> Everything after `=` on a line is read as the value — including `# comments`.
> ```
> # WRONG (the comment becomes part of the value):
> MONGO_PASSWORD=secret   # my password
>
> # RIGHT:
> MONGO_PASSWORD=secret
> ```

Generate secrets with `openssl`:
```bash
openssl rand -hex 16   # for passwords
openssl rand -hex 32   # for passkeys
```

Create each `.env` file from the provided example:

```bash
# Infrastructure
cp infrastructure/traefik/.env.example    infrastructure/traefik/.env
cp infrastructure/technitium/.env.example infrastructure/technitium/.env
cp infrastructure/komodo/.env.example     infrastructure/komodo/.env

# Apps
cp apps/homepage/.env.example    apps/homepage/.env
cp apps/uptime-kuma/.env.example apps/uptime-kuma/.env
cp apps/whoami/.env.example      apps/whoami/.env
```

Edit each `.env` file and fill in real values:

| File | Key variables to fill in |
| :--- | :--- |
| `infrastructure/komodo/.env` | `MONGO_PASSWORD`, `KOMODO_PASSKEY`, `KOMODO_INIT_ADMIN_PASSWORD`, `KOMODO_DATABASE_URI`, `KOMODO_HOST` |
| `infrastructure/technitium/.env` | `DNS_SERVER_ADMIN_PASSWORD`, `TZ` |
| `infrastructure/traefik/.env` | *(defaults are usually fine)* |

For `KOMODO_DATABASE_URI`, replace `YOUR_MONGO_PASSWORD_HERE` with the same value you set for `MONGO_PASSWORD`:
```
KOMODO_DATABASE_URI=mongodb://admin:YOUR_MONGO_PASSWORD_HERE@komodo-mongo:27017
```

---

## 2. SSL Certificate Setup

Generate self-signed certificates for the `.lab` domain:
```bash
bash scripts/generate-certs.sh
```

Copy the generated certificates into Traefik's certs directory:
```bash
cp ~/certs/star_lab.crt infrastructure/traefik/certs/
cp ~/certs/star_lab.key infrastructure/traefik/certs/
```

---

## 3. Deploy Infrastructure

### Step 1 — Create the shared proxy network

All services use a shared Docker network called `proxy`. Create it once:
```bash
docker network create proxy
```

### Step 2 — Deploy Traefik

```bash
cd /srv/home-lab/infrastructure/traefik
docker compose up -d
```

Verify: `https://traefik.lab` should show the Traefik dashboard.

### Step 3 — Deploy Technitium DNS

```bash
cd /srv/home-lab/infrastructure/technitium
docker compose up -d
```

Verify: `http://SERVER_IP:5380` should show the Technitium web UI.

### Step 4 — Deploy Komodo

```bash
cd /srv/home-lab/infrastructure/komodo
docker compose up -d
```

Verify: `http://SERVER_IP:9120` should show the Komodo login page.

---

## 4. Deploy Applications

```bash
cd /srv/home-lab/apps/homepage && docker compose up -d
cd /srv/home-lab/apps/uptime-kuma && docker compose up -d
cd /srv/home-lab/apps/whoami && docker compose up -d
```

---

## 5. Post-Deployment Configuration

### Komodo

1. Open `http://SERVER_IP:9120` and log in with the `KOMODO_INIT_ADMIN_USERNAME` / `KOMODO_INIT_ADMIN_PASSWORD` you set.
2. Go to **Servers** → select the **"Local"** server.
3. Set the **Address** to:
   ```
   https://komodo-periphery:8120
   ```
   > ⚠️ Use **HTTPS**, not HTTP. Komodo Periphery auto-generates a self-signed SSL certificate and listens on HTTPS by default.

### Technitium DNS

1. Open `http://SERVER_IP:5380` and log in.
2. Go to **Zones** → **Add Zone**.
   - Zone name: `lab`
   - Type: **Primary**
3. Inside the `lab` zone, add two records:
   - `@` → **A** record → your server's IP address
   - `*` → **A** record → your server's IP address (wildcard — catches all `*.lab` subdomains)

### DNS on the Server

Ensure the server itself resolves `.lab` domains via Technitium. The `/etc/systemd/resolved.conf.d/technitium.conf` file (created in the Prerequisites step) should already point DNS to `127.0.0.1`.

Verify DNS resolution:
```bash
sudo systemctl restart systemd-resolved
nslookup home.lab 127.0.0.1
```

### Tailscale (Remote Access)

In the Tailscale admin console, update the **Global Nameserver** to point to your server's Tailscale IP. This lets remote devices resolve `.lab` domains through Technitium.

---

## 6. Verification

```bash
# Check all containers are running
docker ps

# Verify DNS resolution
nslookup home.lab 127.0.0.1

# Verify full chain: DNS → Traefik → Container
curl -k https://whoami.lab
```

**Service URLs:**

| Service | URL |
| :--- | :--- |
| Traefik Dashboard | `https://traefik.lab` |
| Technitium DNS | `https://dns.lab` |
| Komodo | `https://komodo.lab` |
| Homepage | `https://home.lab` |
| Uptime Kuma | `https://uptime.lab` |
| WhoAmI | `https://whoami.lab` |

---

## 7. Troubleshooting

**Port 53 already in use (Technitium won't start)**
Ubuntu's `systemd-resolved` DNS stub listener occupies port 53. Disable it:
```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/technitium.conf <<EOF
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
EOF
sudo mv /etc/resolv.conf /etc/resolv.conf.backup
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved
```

**Komodo shows "no login method configured"**
Ensure `KOMODO_LOCAL_AUTH=true` is set in `infrastructure/komodo/.env`. Restart the stack after changing it:
```bash
docker compose -f infrastructure/komodo/compose.yaml up -d
```

**Komodo Core can't reach MongoDB**
- Ensure the `komodo-internal` Docker network was created by Compose (it is created automatically when you run `docker compose up -d`).
- Verify `KOMODO_DATABASE_URI` in `.env` uses the container name `komodo-mongo` as the host: `mongodb://admin:PASSWORD@komodo-mongo:27017`.

**Komodo Periphery "ServerUnreachable" error**
Set the server address to `https://komodo-periphery:8120` — Periphery uses HTTPS with a self-signed certificate by default. Using `http://` will fail.

**Docker `.env` values contain unexpected characters**
Docker `.env` files do **not** support inline comments. Everything after `=` on a value line is read literally, including `# text`. Remove any inline comments and keep comments on their own lines.
