#!/bin/bash
function cleanup() {
  sudo ip netns del ns1
  sudo ip netns del ns2
  sudo ip netns del router-ns
  sudo ip link del br0
  sudo ip link del br1
}

# Cleanup any previous configuration
cleanup

#*** START Required Tasks 1 (Create Network Bridges)
sudo ip link add name br0 type bridge
sudo ip link add name br1 type bridge
sudo ip link set br0 up
sudo ip link set br1 up
sudo ip link show
#*** END Required Tasks 1



#*** START Required Tasks 2 (⁠Create Network Namespaces)
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add router-ns
sudo ip netns show
#*** END Required Tasks 2


#*** START Required Tasks 3 (⁠⁠Create Virtual Interfaces and Connections)
sudo ip link add veth-ns1 type veth peer name veth-br0
sudo ip link set veth-ns1 netns ns1
sudo ip link set veth-br0 master br0
sudo ip link set veth-br0 up
sudo ip netns exec ns1 ip link set veth-ns1 up

sudo ip link add veth-ns2 type veth peer name veth-br1
sudo ip link set veth-ns2 netns ns2
sudo ip link set veth-br1 master br1
sudo ip link set veth-br1 up
sudo ip netns exec ns2 ip link set veth-ns2 up

sudo ip link add veth-router-br0 type veth peer name veth-router0
sudo ip link set veth-router0 netns router-ns
sudo ip link set veth-router-br0 master br0
sudo ip link set veth-router-br0 up
sudo ip netns exec router-ns ip link set veth-router0 up

sudo ip link add veth-router-br1 type veth peer name veth-router1
sudo ip link set veth-router1 netns router-ns
sudo ip link set veth-router-br1 master br1
sudo ip link set veth-router-br1 up
sudo ip netns exec router-ns ip link set veth-router1 up

sudo ip link show
#*** END Required Tasks 3

#*** START Required Tasks 4 (⁠Configure IP Addresses)
sudo ip netns exec ns1 ip addr add 192.168.10.2/24 dev veth-ns1
sudo ip netns exec ns1 ip route add default via 192.168.10.254

sudo ip netns exec ns2 ip addr add 192.168.20.2/24 dev veth-ns2
sudo ip netns exec ns2 ip route add default via 192.168.20.254

sudo ip netns exec router-ns ip addr add 192.168.10.254/24 dev veth-router0
sudo ip netns exec router-ns ip addr add 192.168.20.254/24 dev veth-router1

#*** END Required Tasks 4


# Enable IP forwarding in router-ns
sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

echo "Setup complete. Testing connectivity..."
# Test connectivity
sudo ip netns exec ns1 ping -c 3 192.168.20.2
sudo ip netns exec ns2 ping -c 3 192.168.10.2

cleanup