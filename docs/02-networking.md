# 02 - Networking & Traffic Management

This section documents how the lab is accessed remotely and how traffic is routed internally using a custom `.lab` domain.

## 1. Remote Access (Tailscale)
Tailscale is used to create a secure Mesh VPN, eliminating the need to open ports on the router.

### 1.1 Installation
First create a tailscale account on https://tailscale.com/ and install the tailscale client on your machine

Then run the following on the Ubuntu Server:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 1.2 Configuration

1. Run `sudo tailscale up` and authenticate via the generated link.
2. **Get the Tailscale IP:** Run `tailscale ip -4` (e.g., `100.x.y.z`).
3. **Admin Console Settings:**
* Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/dns).
* **DNS Settings:** Add the server's **Tailscale IP** (`100.x.y.z`) as a Global Nameserver.
* **Override Local DNS:** Enable this to force clients to use our Technitium instance.

### 1.3 Remote Access (Tailscale Subnet Router)

This configuration enables **Site-to-Site** style access. It allows remote devices (laptop at work/travel) to access the Home Lab using local IP addresses (e.g., `192.168.1.10`) and local domain names (`*.lab`) via the encrypted Tailscale tunnel.

Without this, remote devices can only access the server via its 100.x.y.z Tailscale IP.

#### a. The Concept
By enabling **Subnet Routes**, the Home Server acts as a gateway. It advertises the entire home network (`192.168.1.0/24`) to the Tailscale mesh. When a remote laptop requests `192.168.1.10`, Tailscale intercepts the packet, encrypts it, sends it to the Home Server, and the Home Server forwards it to the local LAN.

#### b. Server Configuration (CLI)
Run the following command on the Home Server (Ubuntu) to start advertising the local subnet to the Tailscale network.

```bash
# --advertise-routes: Tells Tailscale to share the 192.168.1.x network
# --reset: Ensures previous settings are overwritten with this new config
sudo tailscale up --advertise-routes=192.168.1.0/24 --reset
```

#### c. Approval (Web Console)

For security reasons, routes are not enabled automatically. You must explicitly approve them in the admin panel.

1. Log in to the **[Tailscale Admin Console](https://login.tailscale.com/admin/machines)**.
2. Locate the **Home Server** in the machines list.
3. Look for a **"Subnets"** badge (it may be gray with an `!` icon).
4. Click the **Three Dots (...)** menu on the right side of the machine row.
5. Select **Edit Route Settings**.
6. **Check the box** next to `192.168.1.0/24`.
7. Click **Save**.

#### d. Verification

From a remote network (e.g., Office Wi-Fi or Mobile Data):

1. Open a terminal.
2. Ping the local server IP: `ping 192.168.1.10`.
3. If it replies, the bridge is active, and `*.lab` domains will now resolve correctly.



## 2. DNS Resolution (Technitium DNS Server)

Technitium DNS Server serves as the local DNS resolver for our private domains, with a built-in web UI for management.

### 2.1 Deployment

Deployed via Komodo Stack (see `infrastructure/technitium/compose.yaml`).

```bash
cd infrastructure/technitium
cp .env.example .env
nano .env   # Set DNS_SERVER_ADMIN_PASSWORD and other values
docker compose up -d
```

* **Web Interface:** `https://dns.lab` (via Traefik) or `http://<SERVER-IP>:5380`.
* **DNS Port:** `53`.

### 2.2 Configuration

1. Access Technitium at `https://dns.lab` or `http://<SERVER-IP>:5380`.
2. Log in with the admin password set in `.env`.
3. **DNS Rewrites (Zones):**
   * Go to **Zones** -> **Add Zone**.
   * Add a wildcard rewrite: `*.lab` -> `<SERVER-IP>`.
   *(This directs all traffic for `anything.lab` to our Traefik proxy).*



## 3. Reverse Proxy (Traefik)

Traefik handles the routing of HTTP/HTTPS requests to the correct container based on the domain name. Services declare their routing rules via Docker labels.

### 3.1 Deployment

Deployed via Komodo Stack (see `infrastructure/traefik/compose.yaml`).

```bash
cd infrastructure/traefik
cp .env.example .env
# Copy your SSL certificates to ./certs/
cp ~/certs/star_lab.crt ./certs/
cp ~/certs/star_lab.key ./certs/
docker compose up -d
```

* **Dashboard:** `https://traefik.lab`.
* **HTTP/HTTPS:** Ports `80` and `443`.

### 3.2 Service Routing

Each service declares its own routing rules using Traefik labels in its `compose.yaml`. No manual configuration in a central proxy UI is required.

| Domain | Service | Internal Port |
| --- | --- | --- |
| `traefik.lab` | Traefik Dashboard | 8080 |
| `komodo.lab` | Komodo Core | 9120 |
| `dns.lab` | Technitium DNS | 5380 |
| `home.lab` | Homepage | 3000 |
| `uptime.lab` | Uptime Kuma | 3001 |
| `whoami.lab` | WhoAmI | 80 |

### 3.3 Adding a New Service

To route a new service through Traefik, add the following labels to its `compose.yaml`:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.lab`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.tls=true"
  - "traefik.http.services.myservice.loadbalancer.server.port=<INTERNAL_PORT>"
```
