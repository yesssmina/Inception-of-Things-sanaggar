#!/bin/bash

# ============================================
# Script d'installation K3s SERVER
# ============================================

SERVER_IP=$1

echo "[INFO] Installation de K3s en mode SERVER..."

# Installation de K3s avec l'IP spécifique
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --bind-address=${SERVER_IP} --advertise-address=${SERVER_IP} --write-kubeconfig-mode=644" sh -

# Attendre que K3s soit prêt
echo "[INFO] Attente du démarrage de K3s..."
sleep 10

# Vérifier que K3s fonctionne
kubectl get nodes

# Sauvegarder le token pour le worker
echo "[INFO] Token K3s sauvegardé dans /vagrant_shared/node-token"
mkdir -p /vagrant_shared
cp /var/lib/rancher/k3s/server/node-token /vagrant_shared/

echo "[INFO] K3s Server installé avec succès !"
