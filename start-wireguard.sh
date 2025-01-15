#!/bin/bash

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Display status for debugging
echo "WireGuard and network setup complete:"

sudo ip route
sudo ip rule show

sudo ip addr show
sudo ip route show
sudo iptables -t nat -L -v -n
sudo wg show

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl --interface wg0 -v ifconfig.me

# Execute CMD
exec "tail /dev/null"