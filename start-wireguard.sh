#!/bin/bash

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Remove conflicting route for tap0 if it exists
sudo ip route del 192.168.100.0/24 dev tap0 2>/dev/null || true

# Create and configure the TAP device for QEMU
sudo ip tuntap add dev tap0 mode tap user $(whoami) 2>/dev/null || true
sudo ip link set tap0 up
sudo ip addr add 192.168.100.1/24 dev tap0
sudo ip route add 192.168.100.0/24 dev tap0

# Ensure the TAP device traffic routes through WireGuard
sudo iptables -t nat -A POSTROUTING -o wg0 -s 192.168.100.0/24 -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o wg0 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Exclude VNC traffic (ports 5900-5999) from WireGuard
sudo ip rule add fwmark 1 table main
sudo iptables -t mangle -A OUTPUT -p tcp --dport 5900:5999 -j MARK --set-mark 1
sudo iptables -t mangle -A OUTPUT -p udp --dport 5900:5999 -j MARK --set-mark 1

# Ensure the default route is through WireGuard for all other traffic
sudo ip route del default dev eth0 2>/dev/null || true
sudo ip route add default dev wg0

# Flush the routing cache to apply changes
sudo ip route flush cache

# Update DNS to ensure proper resolution
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

# Display status for debugging
echo "WireGuard and network setup complete:"
sudo wg show
sudo ip route
sudo ip rule show

# Test connectivity to an external IP
ping -c 4 8.8.8.8

# Check public IP (should match the WireGuard server's IP)
curl ifconfig.me

# Execute CMD
exec "$@"