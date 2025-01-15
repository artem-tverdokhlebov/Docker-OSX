#!/bin/bash

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Ensure default route is through WireGuard
sudo ip route del default dev eth0 2>/dev/null || true
sudo ip route add default dev wg0

# Exclude VNC traffic (port 5999) from WireGuard
sudo ip rule add fwmark 1 table main
sudo iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Ensure that the main routing table is used for traffic marked with 1
sudo ip route flush cache

# Display WireGuard status
echo "WireGuard setup complete:"
sudo wg show
sudo ip rule show
sudo ip route

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl ifconfig.me

# Execute CMD
exec "$@"