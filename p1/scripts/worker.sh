#!/bin/bash

# ============================================
# Script d'installation K3s AGENT (Worker)
# ============================================

SERVER_IP=$1
WORKER_IP=$2

echo "[INFO] Installation de K3s en mode AGENT..."

# Attendre que le token soit disponible
echo "[INFO] Attente du token du server..."
while [ ! -f /vagrant_shared/node-token ]; do
  echo "[INFO] Token non trouvé, attente..."
  sleep 5
done

# Récupérer le token
TOKEN=$(cat /vagrant_shared/node-token)

echo "[INFO] Token récupéré, installation de l'agent..."

# Installation de K3s en mode agent
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP}" K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${TOKEN}" sh -

echo "[INFO] K3s Agent installé avec succès !"
