#!/bin/bash

# Enable WireGuard
sudo wg-quick up /etc/wireguard/wg0.conf

# Set the default route to WireGuard
sudo ip route add default dev wg0

# Execute CMD
exec "$@"