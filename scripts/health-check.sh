#!/bin/bash
set -euo pipefail

# Comprehensive cluster health check and troubleshooting script
# Usage: ./health-check.sh

echo "🔍 Kubernetes CI/CD Stack Health Check"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "\n${BLUE}1. Cluster Connectivity${NC}"
echo "------------------------"
kubectl cluster-info --request-timeout=10s >/dev/null 2>&1
check_status "Kubernetes API server accessible"

echo -e "\n${BLUE}2. Node Status${NC}"
echo "---------------"
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | wc -l)
if [ "$NOT_READY" -eq 0 ]; then
    TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
    echo -e "${GREEN}✅ All $TOTAL_NODES nodes are Ready${NC}"
else
    echo -e "${RED}❌ $NOT_READY nodes are not Ready${NC}"
    kubectl get nodes
fi

echo -e "\n${BLUE}3. Critical Namespaces${NC}"
echo "----------------------"
for ns in kube-system metallb-system ingress cert-manager longhorn-system argocd; do
    if kubectl get namespace "$ns" >/dev/null 2>&1; then
        check_status "Namespace $ns exists"
    else
        echo -e "${RED}❌ Namespace $ns missing${NC}"
    fi
done

echo -e "\n${BLUE}4. Pod Status by Namespace${NC}"
echo "----------------------------"

check_namespace_pods() {
    local namespace=$1
    local expected_running=${2:-1}
    
    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo -e "${RED}❌ Namespace $namespace does not exist${NC}"
        return 1
    fi
    
    local total_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
    local running_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep " Running " | wc -l)
    local pending_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep " Pending " | wc -l)
    local failed_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep -E " (Failed|Error|CrashLoopBackOff|ImagePullBackOff) " | wc -l)
    
    echo "  📦 $namespace: $running_pods/$total_pods running"
    
    if [ "$failed_pods" -gt 0 ]; then
        echo -e "    ${RED}❌ $failed_pods failed pods${NC}"
        kubectl get pods -n "$namespace" | grep -E " (Failed|Error|CrashLoopBackOff|ImagePullBackOff) "
    fi
    
    if [ "$pending_pods" -gt 0 ]; then
        echo -e "    ${YELLOW}⚠️  $pending_pods pending pods${NC}"
        kubectl get pods -n "$namespace" | grep " Pending "
    fi
}

check_namespace_pods "metallb-system"
check_namespace_pods "ingress"  
check_namespace_pods "cert-manager"
check_namespace_pods "longhorn-system"
check_namespace_pods "argocd"

echo -e "\n${BLUE}5. LoadBalancer Services${NC}"
echo "-------------------------"
LB_SERVICES=$(kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null)
if [ -n "$LB_SERVICES" ]; then
    echo "$LB_SERVICES" | while read line; do
        EXTERNAL_IP=$(echo "$line" | awk '{print $5}')
        SERVICE_NAME=$(echo "$line" | awk '{print $1"/"$2}')
        if [[ "$EXTERNAL_IP" == "<pending>" ]]; then
            echo -e "${YELLOW}⚠️  $SERVICE_NAME: External IP pending${NC}"
        else
            echo -e "${GREEN}✅ $SERVICE_NAME: $EXTERNAL_IP${NC}"
        fi
    done
else
    echo -e "${RED}❌ No LoadBalancer services found${NC}"
fi

echo -e "\n${BLUE}6. Certificate Status${NC}"
echo "---------------------"
if kubectl get certificates -n cert-manager >/dev/null 2>&1; then
    kubectl get certificates -n cert-manager --no-headers 2>/dev/null | while read line; do
        CERT_NAME=$(echo "$line" | awk '{print $1}')
        READY=$(echo "$line" | awk '{print $2}')
        if [[ "$READY" == "True" ]]; then
            echo -e "${GREEN}✅ Certificate $CERT_NAME is ready${NC}"
        else
            echo -e "${RED}❌ Certificate $CERT_NAME is not ready${NC}"
        fi
    done
else
    echo -e "${RED}❌ No certificates found in cert-manager namespace${NC}"
fi

echo -e "\n${BLUE}7. Ingress Resources${NC}"
echo "--------------------"
INGRESS_COUNT=$(kubectl get ingress -A --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_COUNT" -gt 0 ]; then
    kubectl get ingress -A --no-headers 2>/dev/null | while read line; do
        NAMESPACE=$(echo "$line" | awk '{print $1}')
        INGRESS_NAME=$(echo "$line" | awk '{print $2}')
        HOSTS=$(echo "$line" | awk '{print $4}')
        echo -e "${GREEN}✅ $NAMESPACE/$INGRESS_NAME → $HOSTS${NC}"
    done
else
    echo -e "${RED}❌ No ingress resources found${NC}"
fi

echo -e "\n${BLUE}8. DNS and HTTPS Connectivity${NC}"
echo "--------------------------------"
test_https_endpoint() {
    local url=$1
    local name=$2
    
    info "Testing $name ($url)"
    
    # Test DNS resolution
    DOMAIN=$(echo "$url" | sed 's/https\?:\/\///' | cut -d'/' -f1)
    if nslookup "$DOMAIN" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ DNS resolution for $DOMAIN${NC}"
    else
        echo -e "  ${RED}❌ DNS resolution failed for $DOMAIN${NC}"
        return 1
    fi
    
    # Test HTTPS connectivity (force HTTPS only)
    if curl -I --connect-timeout 10 --max-time 30 --fail "$url" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ HTTPS connectivity to $url${NC}"
        
        # Test if HTTP redirects to HTTPS
        HTTP_URL=$(echo "$url" | sed 's/https:/http:/')
        if curl -I --connect-timeout 5 --max-time 10 "$HTTP_URL" 2>/dev/null | grep -q "301\|302"; then
            echo -e "  ${GREEN}✅ HTTP correctly redirects to HTTPS${NC}"
        else
            echo -e "  ${YELLOW}⚠️  HTTP redirect not confirmed (this is okay if HTTP is disabled)${NC}"
        fi
    else
        echo -e "  ${RED}❌ HTTPS connectivity failed to $url${NC}"
        return 1
    fi
}

test_https_endpoint "https://argocd.cicd.bitsb.dev" "ArgoCD"
test_https_endpoint "https://longhorn.cicd.bitsb.dev" "Longhorn"

echo -e "\n${BLUE}9. ArgoCD Admin Password${NC}"
echo "-------------------------"
if kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ArgoCD admin password secret exists${NC}"
    echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
else
    echo -e "${RED}❌ ArgoCD admin password secret not found${NC}"
fi

echo -e "\n${BLUE}10. Storage Classes${NC}"
echo "-------------------"
if kubectl get storageclass longhorn >/dev/null 2>&1; then
    DEFAULT_SC=$(kubectl get storageclass longhorn -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')
    if [[ "$DEFAULT_SC" == "true" ]]; then
        echo -e "${GREEN}✅ Longhorn storage class is default${NC}"
    else
        echo -e "${YELLOW}⚠️  Longhorn storage class exists but not default${NC}"
    fi
else
    echo -e "${RED}❌ Longhorn storage class not found${NC}"
fi

echo -e "\n${BLUE}11. Resource Usage Summary${NC}"
echo "----------------------------"
echo "Node resource allocation:"
kubectl describe nodes | grep -A5 "Allocated resources:" | grep -E "(cpu|memory)" | sort | uniq -c

echo -e "\n${BLUE}12. Recent Events (Last 10)${NC}"
echo "------------------------------"
kubectl get events -A --sort-by='.lastTimestamp' | tail -10

echo -e "\n${BLUE}🏥 Health Check Complete${NC}"
echo "========================="

# Summary
FAILED_CHECKS=0

# Count issues
if ! kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then ((FAILED_CHECKS++)); fi
if [ "$(kubectl get nodes --no-headers | grep -v " Ready " | wc -l)" -gt 0 ]; then ((FAILED_CHECKS++)); fi
if [ "$(kubectl get pods -A --no-headers | grep -E " (Failed|Error|CrashLoopBackOff|ImagePullBackOff) " | wc -l)" -gt 0 ]; then ((FAILED_CHECKS++)); fi

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}🎉 All systems operational!${NC}"
    echo -e "${GREEN}Your cluster is healthy and ready to use.${NC}"
else
    echo -e "${RED}⚠️  Found $FAILED_CHECKS issues that need attention.${NC}"
    echo -e "${YELLOW}Review the output above and check the troubleshooting section in README.md${NC}"
fi

echo -e "\n${BLUE}Quick Access Commands:${NC}"
echo "# Port forward ArgoCD (if ingress issues):"
echo "kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo ""
echo "# Port forward Longhorn (if ingress issues):"  
echo "kubectl port-forward -n longhorn-system svc/longhorn-frontend 8081:80"
echo ""
echo "# Port forward Kong Admin (HTTPS only):"
echo "kubectl port-forward -n ingress svc/kong-kong-admin 8444:8444"
echo ""
echo "# Watch pod status:"
echo "kubectl get pods -A --watch"
