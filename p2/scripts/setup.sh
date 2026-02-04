#!/bin/bash

# K3s SERVER Installation Script + Apps Deployment

SERVER_IP="192.168.56.110"

echo "[INFO] Installing K3s in SERVER mode..."

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --node-ip=${SERVER_IP} \
    --bind-address=${SERVER_IP} \
    --advertise-address=${SERVER_IP} \
    --write-kubeconfig-mode=644" sh -

# Wait for K3s to be ready
echo "[INFO] Waiting for K3s to start..."
sleep 15

# Verify K3s is working
kubectl get nodes

# Apply Kubernetes configurations
echo "[INFO] Deploying applications..."
kubectl apply -f /vagrant_confs/

# Wait for pods to be ready
echo "[INFO] Waiting for pods to start..."
sleep 10

# Display final state
echo "[INFO] Cluster status:"
kubectl get all
kubectl get ingress

echo "[INFO] Setup completed!"
