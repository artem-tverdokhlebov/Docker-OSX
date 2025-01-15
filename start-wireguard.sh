#!/bin/bash

# Bring up WireGuard
wg-quick up /etc/wireguard/wg0.conf

# Route all traffic through WireGuard except VNC
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5900:5999 -j ACCEPT

# Start Docker-OSX services
exec "$@"
