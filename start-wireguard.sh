#!/bin/bash

# Stop WireGuard if already running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Remove the existing default route (via eth0)
sudo ip route del default dev eth0 2>/dev/null || true

# Add a default route via WireGuard
sudo ip route add default dev wg0

# Verify and log setup
echo "WireGuard setup complete:"
sudo wg show
sudo ip route

# Execute CMD
exec "$@"