#!/bin/bash

# Stop WireGuard if already running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Clean up existing routes and rules
sudo ip route del default dev wg0 2>/dev/null || true
sudo ip addr flush dev wg0 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Add default route through WireGuard
sudo ip route add default dev wg0

# Verify and log setup
echo "WireGuard setup complete:"
sudo wg show
sudo ip route

cat /etc/resolv.conf

# Execute CMD
exec "$@"