#!/bin/bash

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Create and configure TAP device
sudo ip tuntap add dev tap0 mode tap user $(whoami)
sudo ip link set tap0 up
sudo ip addr add 192.168.100.1/24 dev tap0
sudo ip route add 192.168.100.0/24 dev tap0

# NAT traffic from tap0 through wg0
sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o wg0 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Exclude VNC traffic from WireGuard
sudo ip rule add fwmark 1 table main
sudo iptables -t mangle -A OUTPUT -p tcp --dport ${VNC_PORT:-5900} -j MARK --set-mark 1

# Ensure default route is through WireGuard
sudo ip route del default dev eth0 2>/dev/null || true
sudo ip route add default dev wg0

# Flush routing cache
sudo ip route flush cache

# Display setup details for debugging
echo "WireGuard setup complete:"
sudo wg show
sudo ip route

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl ifconfig.me

# Execute CMD
exec "$@"