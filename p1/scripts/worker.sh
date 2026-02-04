#!/bin/bash

# K3s AGENT (Worker) Installation Script

# Get IPs from arguments passed by Vagrantfile
SERVER_IP=$1   # IP of the server to connect to
WORKER_IP=$2   # IP of this worker node

echo "[INFO] Installing K3s in AGENT mode..."

# Wait for the token file to be available
echo "[INFO] Waiting for server token..."
while [ ! -f /vagrant_shared/node-token ]; do
  echo "[INFO] Token not found, waiting..."
  sleep 5
done

# Read the token from the shared file
TOKEN=$(cat /vagrant_shared/node-token)
echo "[INFO] Token retrieved, installing agent..."

# Install K3s in agent mode
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP}" K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${TOKEN}" sh -

echo "[INFO] K3s Agent installed successfully!"
