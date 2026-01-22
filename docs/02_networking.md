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
* **Override Local DNS:** Enable this to force clients to use our AdGuard instance.

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



## 2. DNS Resolution (AdGuard Home)

AdGuard Home serves as the network-wide ad blocker and the local DNS resolver for our private domains.

### 2.1 Deployment

Deployed via Portainer Stack (see `stacks/adguard home`).

* **Web Interface:** Port `8081` (Mapped to internal `80`).
* **DNS Port:** `53`.

### 2.2 Configuration

1. Access AdGuard at `http://<SERVER-IP>:8081`.
2. **Setup Wizard:**
* **Admin Web Interface:** Listen on interface `eth0` (or `all`), Port `80`.
* **DNS Server:** Listen on Port `53`.


3. **DNS Rewrites:**
* Go to **Filters** -> **DNS Rewrites**.
* Add a wildcard rewrite: `*.lab` -> `<SERVER-IP>`.
*(This directs all traffic for `anything.lab` to our Nginx proxy).*



## 3. Reverse Proxy (Nginx Proxy Manager)

Nginx Proxy Manager (NPM) handles the routing of HTTP requests to the correct container based on the domain name.

### 3.1 Deployment

Deployed via Portainer Stack (see `stacks/nginx`).

* **Admin Interface:** Port `81`.
* **HTTP/HTTPS:** Ports `80` and `443`.

### 3.2 Proxy Hosts Configuration

For every service (e.g., Portainer, Homepage), a **Proxy Host** is created in NPM:

| Domain | Forward Host IP | Forward Port | Scheme |
| --- | --- | --- | --- |
| `portainer.lab` | `192.168.1.x` | `9443` | `https` |
| `home.lab` | `192.168.1.x` | `3001` | `http` |
| `adguard.lab` | `192.168.1.x` | `8081` | `http` |

### 3.3 Special Configuration for Portainer

To fix CSRF/Origin errors when accessing Portainer via domain, add this to the **Advanced** tab of the Proxy Host:

```nginx
# Simple SSL Bypass for viewing
proxy_ssl_verify off;
proxy_ssl_server_name on;
```
