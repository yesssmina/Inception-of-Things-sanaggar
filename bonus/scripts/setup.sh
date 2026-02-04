#!/bin/bash

#Gitlab Installation + Argo CD reconfiguration

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"
P3_DIR="$SCRIPT_DIR/../../p3"

# 1. Check if cluster exists, if not run p3 setup
echo -e "${BLUE}[INFO]${NC} Checking K3d cluster..."
if ! k3d cluster list 2>/dev/null | grep -q "iot-cluster"; then
    echo -e "${YELLOW}[WARN]${NC} Cluster not found."
    echo -e "${BLUE}[INFO]${NC} Running p3/scripts/setup.sh first..."
    if [ -f "$P3_DIR/scripts/setup.sh" ]; then
        (cd "$P3_DIR" && bash scripts/setup.sh)
    else
        echo -e "${RED}[ERROR]${NC} p3/scripts/setup.sh not found!"
        exit 1
    fi
fi
echo -e "${GREEN}[OK]${NC} Cluster ready"

# 2. Create gitlab namespace
echo -e "${BLUE}[INFO]${NC} Creating gitlab namespace..."
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}[OK]${NC} Namespace gitlab created"

# 3. Deploy Gitlab from config file
echo -e "${BLUE}[INFO]${NC} Deploying Gitlab..."
kubectl apply -f "$CONFS_DIR/gitlab.yaml"
echo -e "${GREEN}[OK]${NC} Gitlab deployment created"

# 4. Wait for Gitlab to be ready
echo -e "${BLUE}[INFO]${NC} Waiting for Gitlab pod to start (5-10 minutes)..."
kubectl wait --for=condition=Ready pod -l app=gitlab -n gitlab --timeout=600s
echo -e "${GREEN}[OK]${NC} Gitlab pod is running"

# 5. Wait for Gitlab to fully initialize
echo -e "${BLUE}[INFO]${NC} Waiting 90 seconds for Gitlab to fully initialize..."
sleep 90

# 6. Reconfigure Argo CD to use Gitlab
echo -e "${BLUE}[INFO]${NC} Reconfiguring Argo CD to use Gitlab..."
kubectl delete application wil-playground -n argocd 2>/dev/null || true
kubectl apply -f "$CONFS_DIR/argocd-app.yaml"
echo -e "${GREEN}[OK]${NC} Argo CD reconfigured to use Gitlab"

# 7. Get passwords
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
GITLAB_POD=$(kubectl get pod -n gitlab -l app=gitlab -o jsonpath='{.items[0].metadata.name}')
GITLAB_PASSWORD=$(kubectl exec -n gitlab $GITLAB_POD -- cat /etc/gitlab/initial_root_password 2>/dev/null | grep "Password:" | awk '{print $2}' || echo "Not ready yet - wait a few minutes")

# 8. Display summary
echo ""
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}         BONUS INSTALLATION COMPLETE              ${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
echo ""
echo -e "${BLUE}[INFO]${NC} Namespaces:"
kubectl get ns | grep -E "NAME|argocd|dev|gitlab"
echo ""
echo -e "${BLUE}[INFO]${NC} Pods:"
kubectl get pods -n gitlab
kubectl get pods -n dev
echo ""
echo -e "${BLUE}[INFO]${NC} Argo CD Application:"
kubectl get applications -n argocd
echo ""
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}              ACCESS INFORMATION                  ${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
echo ""
echo -e "${YELLOW}ARGO CD:${NC}"
echo "  Command:  kubectl port-forward svc/argocd-server -n argocd 9090:443"
echo "  URL:      https://localhost:9090"
echo "  Username: admin"
echo -e "  Password: ${GREEN}$ARGOCD_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}GITLAB:${NC}"
echo "  Command:  kubectl port-forward svc/gitlab -n gitlab 8181:80"
echo "  URL:      http://localhost:8181"
echo "  Username: root"
echo -e "  Password: ${GREEN}$GITLAB_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}APPLICATION:${NC}"
echo "  Command:  kubectl port-forward svc/wil-playground-svc -n dev 9999:8888"
echo "  Test:     curl http://localhost:9999"
echo ""
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}              MANUAL STEPS REQUIRED               ${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
echo ""
echo "1. Access Gitlab: http://localhost:8181"
echo "2. Create project: sanaggar-iot-gitlab (public, no README)"
echo "3. Clone and push:"
echo "   git clone http://localhost:8181/root/sanaggar-iot-gitlab.git"
echo "   cd sanaggar-iot-gitlab"
echo "   # Create deployment.yaml with wil42/playground:v1"
echo "   git add . && git commit -m 'v1' && git push origin main"
echo "4. Argo CD will auto-sync from Gitlab"
echo ""
echo -e "${GREEN}--------------------------------------------------${NC}"
