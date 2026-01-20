# 02 - Networking & Traffic Management

This section documents how the lab is accessed remotely and how traffic is routed internally using a custom `.lab` domain.

## 1. Remote Access (Tailscale)
Tailscale is used to create a secure Mesh VPN, eliminating the need to open ports on the router.

### 1.1 Installation
First create a tailscale account on https://tailscale.com/ and install the tailscale client on your machine

Then run the following on the Ubuntu Server:
```bash
curl -fsSL [https://tailscale.com/install.sh](https://tailscale.com/install.sh) | sh

```

### 1.2 Configuration

1. Run `sudo tailscale up` and authenticate via the generated link.
2. **Get the Tailscale IP:** Run `tailscale ip -4` (e.g., `100.x.y.z`).
3. **Admin Console Settings:**
* Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/dns).
* **DNS Settings:** Add the server's **Tailscale IP** (`100.x.y.z`) as a Global Nameserver.
* **Override Local DNS:** Enable this to force clients to use our AdGuard instance.



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
location / {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_ssl_verify off;
    proxy_ssl_server_name on;
    
    # Spoof Host and Origin to match internal IP
    proxy_set_header Host "192.168.1.x";
    proxy_set_header Origin "[https://192.168.1.](https://192.168.1.)x:9443";
    
    proxy_pass [https://192.168.1.](https://192.168.1.)x:9443;
}

```

*(Replace `192.168.1.x` with the actual server IP).*
