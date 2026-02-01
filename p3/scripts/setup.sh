#!/bin/bash

# ============================================
# K3d + Argo CD Installation Script
# Part 3 - Inception of Things
# ============================================

set -e  # Stop script on error

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} === Installing K3d and Argo CD ==="

# ============================================
# 1. Check/Install Docker
# ============================================
echo -e "${BLUE}[INFO]${NC} Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}[OK]${NC} Docker installed"
else
    echo -e "${GREEN}[OK]${NC} Docker already installed: $(docker --version)"
fi

# ============================================
# 2. Check/Install kubectl
# ============================================
echo -e "${BLUE}[INFO]${NC} Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo -e "${GREEN}[OK]${NC} kubectl installed"
else
    echo -e "${GREEN}[OK]${NC} kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ============================================
# 3. Check/Install K3d
# ============================================
echo -e "${BLUE}[INFO]${NC} Checking K3d..."
if ! command -v k3d &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing K3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo -e "${GREEN}[OK]${NC} K3d installed"
else
    echo -e "${GREEN}[OK]${NC} K3d already installed: $(k3d version)"
fi

# ============================================
# 4. Delete old cluster if exists
# ============================================
echo -e "${BLUE}[INFO]${NC} Cleaning up old clusters..."
k3d cluster delete iot-cluster 2>/dev/null || true

# ============================================
# 5. Create K3d cluster
# ============================================
echo -e "${BLUE}[INFO]${NC} Creating K3d cluster..."
k3d cluster create iot-cluster --port "8080:80@loadbalancer" --port "8888:8888@loadbalancer"

# Wait for cluster to be ready
echo -e "${BLUE}[INFO]${NC} Waiting for cluster to start..."
sleep 10
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "${GREEN}[OK]${NC} K3d cluster created"
kubectl get nodes

# ============================================
# 6. Create namespaces
# ============================================
echo -e "${BLUE}[INFO]${NC} Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev
echo -e "${GREEN}[OK]${NC} Namespaces created"
kubectl get namespaces

# ============================================
# 7. Install Argo CD
# ============================================
echo -e "${BLUE}[INFO]${NC} Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo -e "${BLUE}[INFO]${NC} Waiting for Argo CD to start..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

echo -e "${GREEN}[OK]${NC} Argo CD installed"

# ============================================
# 8. Configure application with Argo CD
# ============================================
echo -e "${BLUE}[INFO]${NC} Configuring application..."

kubectl apply -f - <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-playground
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yesssmina/sanaggar-iot-p3.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
YAML

echo -e "${GREEN}[OK]${NC} Application configured"

# ============================================
# 9. Wait for application to be deployed
# ============================================
echo -e "${BLUE}[INFO]${NC} Waiting for application deployment..."
sleep 30

# ============================================
# 10. Display final information
# ============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}[INFO]${NC} Cluster status:"
kubectl get nodes
echo ""
echo -e "${BLUE}[INFO]${NC} Namespaces:"
kubectl get namespaces
echo ""
echo -e "${BLUE}[INFO]${NC} Pods in argocd:"
kubectl get pods -n argocd
echo ""
echo -e "${BLUE}[INFO]${NC} Pods in dev:"
kubectl get pods -n dev
echo ""

# Get Argo CD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   ARGO CD ACCESS${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "To access Argo CD web interface:"
echo -e "1. Run in another terminal:"
echo -e "   ${BLUE}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo ""
echo -e "2. Open your browser: ${BLUE}https://localhost:8080${NC}"
echo ""
echo -e "3. Credentials:"
echo -e "   Username: ${BLUE}admin${NC}"
echo -e "   Password: ${BLUE}${ARGOCD_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   APPLICATION TEST${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "To test the application:"
echo -e "   ${BLUE}kubectl port-forward svc/wil-playground-svc -n dev 8888:8888${NC}"
echo -e "   Then: ${BLUE}curl http://localhost:8888${NC}"
echo ""
