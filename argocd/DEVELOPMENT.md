# Fresh ArgoCD GitOps Deployment

## Overview
This is a **clean development setup** - no migration concerns, no data retention needed. We'll deploy everything fresh using GitOps.

## 🧹 **Clean Slate Approach**

Since this is a development environment:
- ✅ No data to preserve
- ✅ No production services to maintain
- ✅ Clean deployment from scratch
- ✅ Full GitOps control from day one

## 🚀 **Quick Start**

### Prerequisites
- Clean Kubernetes cluster
- ArgoCD installed
- kubectl access

### Deploy Everything
```bash
# From deployment repository root
cd /path/to/deployment

# Set GitHub credentials (for private repository access)
export GITHUB_USERNAME=your-github-username
export GITHUB_TOKEN=your-github-personal-access-token

# Bootstrap ArgoCD GitOps (creates everything)
./argocd/bootstrap.sh
```

That's it! ArgoCD will deploy:
1. **MetalLB** → LoadBalancer (IP: 192.168.1.240-250)
2. **cert-manager** → TLS + Root CA for `*.bitsb.dev`
3. **Kong** → Ingress controller with HTTPS
4. **Longhorn** → Distributed storage (auto-installs dependencies)
5. **ArgoCD** → Self-managed GitOps platform

### Verify Deployment
```bash
# Watch applications sync
kubectl get applications -n argocd -w

# Check services when ready
kubectl get svc -A -o wide | grep LoadBalancer
kubectl get ingress -A
kubectl get certificates -A

# Access ArgoCD UI
echo "ArgoCD: https://argocd.cicd.bitsb.dev"
```

## 🎯 **What Gets Created**

### Infrastructure
- **MetalLB**: LoadBalancer with IP pool
- **cert-manager**: Root CA + ClusterIssuer for `bitsb.dev`
- **Kong**: Ingress controller with automatic HTTPS redirect
- **Longhorn**: Storage with automatic `open-iscsi` installation

### Platform
- **ArgoCD**: GitOps platform with web UI

### Automation
- **Pre-deploy hooks**: Root CA setup, Longhorn dependencies
- **Post-deploy resources**: MetalLB IP pools, ClusterIssuers
- **Sync waves**: Proper deployment ordering

## 🔍 **Development Workflow**

### Make Changes
1. Edit values files in `stacks/values/`
2. Commit and push to Git
3. ArgoCD automatically syncs changes

### Add New Applications
1. Add to appropriate ApplicationSet
2. Create application manifest
3. Add values file
4. Commit → automatic deployment

### Reset Everything
```bash
# Clean slate reset
kubectl delete applications --all -n argocd
kubectl delete namespaces metallb-system cert-manager ingress longhorn-system

# Redeploy
./argocd/bootstrap.sh
```

## 📊 **Access Points**

Once deployed:
- **ArgoCD UI**: `https://argocd.cicd.bitsb.dev`
- **Longhorn UI**: Will be available when configured
- **Kong Admin**: Available via LoadBalancer service

## ⚡ **Development Benefits**

- **Fast iteration**: Git commit → automatic deployment
- **Clean resets**: Easy to start over
- **Visual monitoring**: ArgoCD UI shows everything
- **No manual steps**: Fully automated infrastructure
- **Local development**: Perfect for dev/testing

## 🛠️ **Troubleshooting**

### Applications Won't Sync
```bash
# Check application status
kubectl get applications -n argocd
kubectl describe application <name> -n argocd

# Manual sync if needed
kubectl patch application <name> -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### Services Not Ready
```bash
# Check pods
kubectl get pods -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Check specific namespace
kubectl describe pods -n <namespace>
```

This development approach gives you a fully automated, GitOps-managed Kubernetes platform that's perfect for learning, testing, and development work!
