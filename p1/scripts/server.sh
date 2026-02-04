#!/bin/bash

# K3s SERVER Installation Script

# Get server IP from first argument passed by Vagrantfile
SERVER_IP=$1

echo "[INFO] Installing K3s in SERVER mode..."

# Install K3s using the official installation script
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --bind-address=${SERVER_IP} --advertise-address=${SERVER_IP} --write-kubeconfig-mode=644" sh -

# Wait for K3s to fully start (services need time to initialize)
echo "[INFO] Waiting for K3s to start..."
sleep 10

# Verify K3s is running by listing nodes
kubectl get nodes

# Save the node token for the worker to join the cluster
echo "[INFO] Saving K3s token to /vagrant_shared/node-token"
mkdir -p /vagrant_shared
cp /var/lib/rancher/k3s/server/node-token /vagrant_shared/

echo "[INFO] K3s Server installed successfully!"
