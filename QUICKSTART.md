# Quick Deployment Reference Card

## 🚀 TL;DR - Deploy Everything Now

### Prerequisites Check (5 minutes)
```bash
# Navigate to the correct starting directory
cd /Users/bits/lab/github/infra

# 1. Verify cluster access
kubectl get nodes

# 2. Check DNS (replace with your IPs)
nslookup argocd.cicd.bitsb.dev
nslookup longhorn.cicd.bitsb.dev

# 3. Verify tools
kubectl version --client
helm version
ansible --version
```

### One-Command Deployment (15 minutes)
```bash
# From the infra directory (important!)
cd infra

# Deploy everything with one command
ansible-playbook ansible/playbooks/stack_deployment.yml \
  -e stack_file=../../../deployment/stacks/cicd-stack.yml

# Post-deployment (apply certificates)
cd ../deployment
chmod +x scripts/post-deployment.sh
./scripts/post-deployment.sh
```

### Verification (2 minutes)
```bash
# Navigate to deployment directory for scripts
cd /Users/bits/lab/github/deployment

# All pods running
kubectl get pods -A | grep -v Running

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Test URLs
curl -I https://argocd.cicd.bitsb.dev
curl -I https://longhorn.cicd.bitsb.dev

# Run comprehensive health check
./scripts/health-check.sh
```

## 📋 Expected Results

### Services Deployed
- ✅ **ArgoCD**: https://argocd.cicd.bitsb.dev
- ✅ **Longhorn**: https://longhorn.cicd.bitsb.dev  
- ✅ **MetalLB**: LoadBalancer provider
- ✅ **Kong**: API Gateway with HTTPS
- ✅ **cert-manager**: Wildcard TLS certificates

### Namespaces Created
- `argocd` - ArgoCD GitOps
- `longhorn-system` - Distributed storage
- `metallb-system` - LoadBalancer provider
- `ingress` - Kong API Gateway
- `cert-manager` - Certificate management

### Certificates Issued
- `wildcard-app-bitsb-dev-tls` → `*.bitsb.dev`
- `wildcard-cicd-bitsb-dev-tls` → `*.cicd.bitsb.dev`

## 🆘 Quick Troubleshooting

### If pods are pending:
```bash
kubectl describe node | grep -A5 "Allocated resources"
kubectl get events -A --sort-by='.lastTimestamp'
```

### If LoadBalancer pending:
```bash
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l app=metallb
```

### If certificates not ready:
```bash
kubectl get certificates -n cert-manager
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager
```

### Emergency access (bypass ingress):
```bash
# ArgoCD port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Longhorn port-forward  
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8081:80

# Kong admin port-forward
kubectl port-forward -n ingress svc/kong-kong-admin 8444:8444
```

---
**⏱️ Total Time: ~20 minutes from start to working cluster**

## 📋 Copy-Paste Commands

### Complete Deployment (one block)
```bash
# Start from the correct directory
cd /Users/bits/lab/github/infra

# Deploy everything
ansible-playbook ansible/playbooks/stack_deployment.yml \
  -e stack_file=../../../deployment/stacks/cicd-stack.yml \
  -v

# Post-deployment setup
cd ../deployment
chmod +x scripts/*.sh
./scripts/post-deployment.sh
./scripts/health-check.sh
```
