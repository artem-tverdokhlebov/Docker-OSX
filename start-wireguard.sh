#!/bin/bash

# Stop WireGuard if already running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Verify and log setup
echo "WireGuard setup complete:"
sudo wg show
sudo ip route

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl ifconfig.me

# Execute CMD
exec "$@"