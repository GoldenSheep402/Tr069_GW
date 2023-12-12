#!/bin/bash
 
DOMAINS=("tr069.glodensheep.top")
INTERFACE='lo0'

if ! ip link show $INTERFACE > /dev/null 2>&1; then
    echo "Interface $INTERFACE does not exist."
    exit 1
fi

IP_ADDR=$(ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
NETMASK=$(ifconfig $INTERFACE | grep 'Mask:' | cut -d: -f4)
NETWORK_SEGMENT=$(ip addr show $INTERFACE | grep 'inet' | grep -v 'inet6' | awk '{print $2}')

# IFS stands for Internal Field Separator
IFS='.' read -r -a ip_array <<< "$IP_ADDR"
IFS='.' read -r -a mask_array <<< "$NETMASK"

network_addr=()
for i in {0..3}; do
    network_addr+=($((${ip_array[i]} & ${mask_array[i]})))
done

GATEWAY_IP="${network_addr[0]}.${network_addr[1]}.${network_addr[2]}.$((${network_addr[3]} + 1))"

NETWORK_ADDRESS="${network_addr[0]}.${network_addr[1]}.${network_addr[2]}.${network_addr[3]}"

echo "Interface       : $INTERFACE"
echo "IP Address      : $IP_ADDR"
echo "Netmask         : $NETMASK"
echo "Network         : $NETWORK_ADDRESS"
echo "Network Segment : $NETWORK_SEGMENT"
echo "Gateway Address : $GATEWAY_IP"

REMOTE_ADDRS=()

for domain in "${DOMAINS[@]}"; do
    ip=$(dig +short $domain | tail -n1)
    if [ -z "$ip" ]; then
        echo "Failed to resolve domain: $domain"
        continue
    fi
    REMOTE_ADDRS+=("$ip")
    echo "Domain: $domain, IP: $ip/32"
    route add -net $ip netmask 255.255.255.255 gw $GATEWAY_IP dev $INTERFACE 
done