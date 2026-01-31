#!/bin/bash

# ============================================
# Script d'installation K3s SERVER + Apps
# ============================================

SERVER_IP="192.168.56.110"

echo "[INFO] Installation de K3s en mode SERVER..."

# Installation de K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --bind-address=${SERVER_IP} --advertise-address=${SERVER_IP} --write-kubeconfig-mode=644" sh -

# Attendre que K3s soit prêt
echo "[INFO] Attente du démarrage de K3s..."
sleep 15

# Vérifier que K3s fonctionne
kubectl get nodes

# Appliquer les configurations Kubernetes
echo "[INFO] Déploiement des applications..."
kubectl apply -f /vagrant_confs/

# Attendre que les pods soient prêts
echo "[INFO] Attente du démarrage des pods..."
sleep 10

# Afficher l'état final
echo "[INFO] État du cluster :"
kubectl get all
kubectl get ingress

echo "[INFO] Installation terminée !"
