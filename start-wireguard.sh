#!/bin/bash

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Clean up any existing configurations
echo "Cleaning up existing configurations..."
sudo ip link delete tap0 2>/dev/null || true
sudo pkill dnsmasq 2>/dev/null || true

# Create TAP interface
echo "Creating TAP interface..."
sudo ip tuntap add dev tap0 mode tap user $(whoami)
sudo ip link set tap0 up
sudo ip addr add 192.168.100.1/24 dev tap0

# Configure NAT
echo "Configuring NAT..."
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tap0 -j ACCEPT

# Set default gateway if needed
echo "Setting up default gateway..."
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}')
if [ -z "$DEFAULT_GATEWAY" ]; then
    echo "Default gateway not set. Adding route via eth0..."
    sudo ip route add default via $(ip route show dev eth0 | grep -oP '(?<=src )\S+')
else
    echo "Default gateway is already set: $DEFAULT_GATEWAY"
fi

# Install and start dnsmasq for DHCP
echo "Configuring DHCP server with dnsmasq..."
sudo bash -c 'cat > /etc/dnsmasq.conf <<EOF
interface=tap0
dhcp-range=192.168.100.50,192.168.100.100,12h
EOF'

sudo dnsmasq --no-daemon --conf-file=/etc/dnsmasq.conf &
DNSMASQ_PID=$!

# Display network setup for debugging
echo "Displaying network configuration for debugging..."
ip addr show
ip route show
sudo iptables -t nat -L -v -n
sudo iptables -L -v -n

# Test connectivity from tap0
echo "Testing internet connectivity through tap0..."
curl --interface tap0 -v http://ifconfig.me
ping -I tap0 -c 4 8.8.8.8

# Wait for user interaction
echo "Setup complete. Press Ctrl+C to exit and clean up."

# Keep the script running to maintain the environment
trap "echo 'Cleaning up...'; sudo ip link delete tap0; sudo pkill dnsmasq; exit" SIGINT SIGTERM
tail -f /dev/null