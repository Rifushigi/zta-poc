#!/bin/bash
# scripts/setup-networks.sh

set -e

echo "Setting up Docker networks for Zero Trust PoC..."

# Create on-premises network
if ! docker network ls | grep -q "on-prem-net"; then
    echo "Creating on-premises network..."
    docker network create \
        --driver bridge \
        --subnet=172.18.0.0/16 \
        --gateway=172.18.0.1 \
        --opt com.docker.network.bridge.name=br-on-prem \
        on-prem-net
else
    echo "On-premises network already exists"
fi

# Create cloud network
if ! docker network ls | grep -q "cloud-net"; then
    echo "Creating cloud network..."
    docker network create \
        --driver bridge \
        --subnet=192.168.0.0/16 \
        --gateway=192.168.0.1 \
        --opt com.docker.network.bridge.name=br-cloud \
        cloud-net
else
    echo "Cloud network already exists"
fi

echo "Network setup complete!"
echo "Available networks:"
docker network ls | grep -E "(on-prem-net|cloud-net)" 