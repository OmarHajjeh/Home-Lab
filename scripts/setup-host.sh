#!/usr/bin/env bash
# setup-host.sh - Initial host setup for the Home Lab server
# Extracted from docs/01-installation.md
# Run as a regular user with sudo privileges.

set -euo pipefail

echo "=== Home Lab Host Setup ==="

# ---------------------------------------------------------------------------
# Section 1: System Update
# ---------------------------------------------------------------------------
echo "[1/4] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install common utility tools
sudo apt install -y curl wget git nano net-tools

echo "System update complete."

# ---------------------------------------------------------------------------
# Section 2: Fix DNS Stub Conflict (Ubuntu-specific)
# Ubuntu's systemd-resolved listens on port 53, which conflicts with
# Technitium DNS. We disable the stub listener so port 53 is free.
# ---------------------------------------------------------------------------
echo "[2/4] Fixing systemd-resolved DNS stub conflict..."

sudo mkdir -p /etc/systemd/resolved.conf.d

sudo tee /etc/systemd/resolved.conf.d/technitium.conf > /dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
EOF

# Backup original resolv.conf (idempotent: skip if symlink already set)
if [ ! -L /etc/resolv.conf ]; then
    sudo mv /etc/resolv.conf /etc/resolv.conf.backup
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
    echo "resolv.conf symlink created."
else
    echo "resolv.conf is already a symlink, skipping."
fi

sudo systemctl restart systemd-resolved
echo "DNS stub listener disabled."

# ---------------------------------------------------------------------------
# Section 3: Install Docker Engine
# ---------------------------------------------------------------------------
echo "[3/4] Installing Docker CE..."

if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    echo "Docker installed successfully."
fi

# Add current user to the docker group (avoids needing sudo for docker commands)
if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "User '$USER' added to the docker group. Log out and back in to apply."
else
    echo "User '$USER' is already in the docker group."
fi

# Create the shared proxy network used by all services
if ! docker network ls --format '{{.Name}}' | grep -q '^proxy$'; then
    docker network create proxy
    echo "Docker 'proxy' network created."
else
    echo "Docker 'proxy' network already exists."
fi

# ---------------------------------------------------------------------------
# Section 4: Verify Docker Installation
# ---------------------------------------------------------------------------
echo "[4/4] Verifying Docker installation..."
docker run --rm hello-world

echo ""
echo "=== Setup complete! ==="
echo "Next steps:"
echo "  1. Deploy infrastructure services from infrastructure/."
echo "  2. Deploy application services from apps/."
