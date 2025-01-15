#!/bin/bash

# Create and configure the TAP device for QEMU
sudo ip tuntap add dev tap0 mode tap user $(whoami) 2>/dev/null || true
sudo ip link set tap0 up
sudo ip addr add 192.168.100.1/24 dev tap0
sudo ip route add 192.168.100.0/24 dev tap0

# Stop WireGuard if running
sudo wg-quick down /etc/wireguard/wg0.conf 2>/dev/null || true

# Start WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Add NAT for QEMU traffic from tap0 through WireGuard
sudo iptables -t nat -A POSTROUTING -o wg0 -s 192.168.100.0/24 -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o wg0 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo dnsmasq --no-daemon --conf-file=/etc/dnsmasq.conf &
DNSMASQ_PID=$!

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