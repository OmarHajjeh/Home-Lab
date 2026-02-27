#!/usr/bin/env bash
# check-wifi.sh - Wi-Fi health check and auto-recovery for Realtek RTL8851BU
# Extracted from docs/04-wifi-adapter.md
# Can be run manually or scheduled via cron: @reboot /path/to/check-wifi.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
INTERFACE_PREFIX="wlx"
MODULE_NAME="8851bu"
DRIVER_DIR="$HOME/rtl8851bu"

echo "Checking Wi-Fi status for $MODULE_NAME..."

# ---------------------------------------------------------------------------
# 1. Check if the wireless interface exists
# ---------------------------------------------------------------------------
if ip link show | grep -q "$INTERFACE_PREFIX"; then
    echo "[OK] Wi-Fi interface is present."
else
    echo "[!] Wi-Fi interface missing. Checking kernel module..."

    # 2. Check if the module is loaded; if not, try modprobe
    if ! lsmod | grep -q "$MODULE_NAME"; then
        echo "[!] Module $MODULE_NAME not loaded. Attempting modprobe..."
        sudo modprobe "$MODULE_NAME"
    fi

    # 3. If the interface is still missing after modprobe, the kernel likely
    #    updated and the out-of-tree driver needs to be recompiled.
    if ! ip link show | grep -q "$INTERFACE_PREFIX"; then
        echo "[!] Interface still missing. Kernel update detected. Re-installing driver..."
        cd "$DRIVER_DIR"
        make clean && make
        sudo make install
        sudo depmod -a
        sudo modprobe "$MODULE_NAME"
        echo "[SUCCESS] Driver re-installed for current kernel: $(uname -r)"
    else
        echo "[OK] Module was re-loaded successfully."
    fi
fi
