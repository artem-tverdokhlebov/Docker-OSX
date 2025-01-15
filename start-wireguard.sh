#!/bin/bash

# Enable WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Create and configure TAP device
sudo ip tuntap add dev tap0 mode tap user $(whoami)
sudo ip link set tap0 up
sudo ip addr add 10.0.0.1/24 dev tap0

# Ensure TAP device routes through WireGuard
sudo ip link set tap0 master wg0

# Set up NAT for WireGuard
sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o wg0 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Exclude VNC traffic (port 5900) from WireGuard
sudo iptables -t nat -A OUTPUT -p tcp --dport 5900 -j ACCEPT

# Set the default route to WireGuard
sudo ip route add default dev wg0

# Execute CMD
exec "$@"