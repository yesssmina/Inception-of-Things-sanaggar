#!/bin/bash

# K3d + Argo CD Installation Script
# Part 3 - Inception of Things

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'



# 1. Check/Install Docker
echo "[INFO] Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "[INFO] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "[OK] Docker installed"
else
    echo "[OK] Docker already installed: $(docker --version)"
fi



# 2. Check/Install kubectl
echo "[INFO] Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "[INFO] Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "[OK] kubectl installed"
else
    echo "[OK] kubectl already installed: $(kubectl version --client 2>/dev/null)"
fi



# 3. Check/Install K3d
echo "[INFO] Checking K3d..."
if ! command -v k3d &> /dev/null; then
    echo "[INFO] Installing K3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "[OK] K3d installed"
else
    echo "[OK] K3d already installed: $(k3d version)"
fi



# 4. Delete old cluster if exists
echo "[INFO] Cleaning up old clusters..."
k3d cluster delete iot-cluster 2>/dev/null || true



# 5. Create K3d cluster
echo "[INFO] Creating K3d cluster..."
k3d cluster create iot-cluster --port "8080:80@loadbalancer" --port "8888:8888@loadbalancer"

echo "[INFO] Waiting for cluster to start..."
sleep 10
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "[OK] K3d cluster created"
kubectl get nodes



# 6. Create namespaces
echo "[INFO] Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev
echo "[OK] Namespaces created"
kubectl get namespaces



# 7. Install Argo CD
echo "[INFO] Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side

echo "[INFO] Waiting for Argo CD to start..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

echo "[OK] Argo CD installed"



# 8. Configure application with Argo CD
echo "[INFO] Configuring application..."
kubectl apply -f confs/application.yaml
echo "[OK] Application configured"



# 9. Wait for application to be deployed
echo "[INFO] Waiting for application deployment..."
sleep 30



# 10. Display final information
echo ""
echo "INSTALLATION COMPLETE!"
echo ""
echo "[INFO] Cluster status:"
kubectl get nodes
echo ""
echo "[INFO] Namespaces:"
kubectl get namespaces
echo ""
echo "[INFO] Pods in argocd:"
kubectl get pods -n argocd
echo ""
echo "[INFO] Pods in dev:"
kubectl get pods -n dev
echo ""

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}--------------------------------------------${NC}"
echo -e "${GREEN}   ARGO CD ACCESS${NC}"
echo -e "${GREEN}--------------------------------------------${NC}"
echo ""
echo -e "To access Argo CD web interface:"
echo -e "1. Run in another terminal:"
echo -e "   ${BLUE}kubectl port-forward svc/argocd-server -n argocd 9090:443${NC}"
echo ""
echo -e "2. Open your browser: ${BLUE}https://localhost:9090${NC}"
echo ""
echo -e "3. Credentials:"
echo -e "   Username: ${BLUE}admin${NC}"
echo -e "   Password: ${BLUE}${ARGOCD_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}--------------------------------------------${NC}"
echo -e "${GREEN}   APPLICATION TEST${NC}"
echo -e "${GREEN}--------------------------------------------${NC}"
echo ""
echo -e "To test the application:"
echo -e "   ${BLUE}kubectl port-forward svc/wil-playground-svc -n dev 9999:8888${NC}"
echo -e "   Then: ${BLUE}curl http://localhost:9999${NC}"
echo ""
