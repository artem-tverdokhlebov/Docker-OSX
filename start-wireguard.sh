#!/bin/bash

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Exclude VNC traffic (port 5999) from WireGuard
sudo ip rule add fwmark 1 table main
sudo iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Ensure default route uses WireGuard for all other traffic
sudo ip route del default dev eth0 2>/dev/null || true
sudo ip route add default dev wg0

# Display status for debugging
echo "WireGuard setup complete:"
sudo wg show
sudo ip route

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl ifconfig.me

# Execute CMD
exec "$@"