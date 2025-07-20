# Migration Guide: Classic Helm → ArgoCD GitOps

## Overview
This guide helps you safely migrate from classic Helm deployments (via Ansible) to ArgoCD GitOps management.

## 🚨 **Important Considerations**

### Data Persistence
- **Longhorn**: PVs and data will persist through migration
- **cert-manager**: Certificates will be recreated automatically
- **ArgoCD**: Existing ArgoCD instance should be preserved (don't remove if currently using it)

### Service Interruption
- **MetalLB**: Brief LoadBalancer service interruption during migration
- **Kong**: Ingress traffic interruption during migration  
- **cert-manager**: Certificate reissuance may take a few minutes

## 🔍 **Pre-Migration Check**

```bash
# Check current Helm releases
helm list -A

# Check existing resources
kubectl get pvc -A
kubectl get certificates -A
kubectl get ingress -A
kubectl get svc -A -o wide | grep LoadBalancer
```

## 📋 **Migration Steps**

### Step 1: Backup Critical Data
```bash
# Backup cert-manager certificates
kubectl get certificates -A -o yaml > backup-certificates.yaml
kubectl get secrets -A -l cert-manager.io/certificate-name -o yaml > backup-cert-secrets.yaml

# Backup Longhorn volumes (optional - data persists)
kubectl get pv -o yaml > backup-persistent-volumes.yaml

# Backup ingress configurations
kubectl get ingress -A -o yaml > backup-ingress.yaml
```

### Step 2: Clean Up Existing Helm Releases

#### Option A: Automated Cleanup (Recommended)
```bash
./argocd/cleanup-helm.sh
```

#### Option B: Manual Cleanup
```bash
# Remove infrastructure Helm releases
helm uninstall metallb -n metallb-system
helm uninstall cert-manager -n cert-manager  
helm uninstall kong -n ingress
helm uninstall longhorn -n longhorn-system

# Keep ArgoCD if it's already running and you want to use it
# helm uninstall argocd -n argocd  # Only if needed
```

### Step 3: Bootstrap ArgoCD GitOps
```bash
# From deployment repository root
./argocd/bootstrap.sh
```

### Step 4: Verify Migration
```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Watch applications sync
watch kubectl get applications -n argocd

# Check services are back online
kubectl get svc -A -o wide | grep LoadBalancer
kubectl get ingress -A
kubectl get certificates -A
```

## ⚠️ **Troubleshooting**

### If Services Don't Start
```bash
# Check application status
kubectl describe application <app-name> -n argocd

# Check application events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Manual sync if needed
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### If Certificates Don't Issue
```bash
# Check cert-manager is running
kubectl get pods -n cert-manager

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check ClusterIssuer status
kubectl get clusterissuer
kubectl describe clusterissuer bitsb-root-ca-issuer
```

### If LoadBalancer IPs Don't Assign
```bash
# Check MetalLB status
kubectl get pods -n metallb-system

# Check IP pools
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

# Check service events
kubectl describe svc <service-name> -n <namespace>
```

## 🔄 **Rollback Plan**

If migration fails, you can rollback:

```bash
# Remove ArgoCD applications
kubectl delete applications --all -n argocd

# Redeploy using Ansible
cd /path/to/infra
ansible-playbook ansible/playbooks/stack_deployment.yml \
  -e stack_file=../deployment/stacks/cicd-stack.yml
```

## ✅ **Post-Migration Verification**

### Check All Services
```bash
# Infrastructure health
kubectl get pods -A
kubectl get svc -A -o wide | grep LoadBalancer
kubectl get ingress -A

# Certificate status
kubectl get certificates -A
curl -k https://argocd.cicd.bitsb.dev/health

# Storage status  
kubectl get storageclass
kubectl get pv
kubectl get pvc -A
```

### Test Applications
- **ArgoCD**: `https://argocd.cicd.bitsb.dev`
- **Longhorn**: Check if storage is working
- **Kong**: Test ingress routing
- **cert-manager**: Verify TLS certificates

## 📝 **Key Differences**

| Aspect | Classic Helm | ArgoCD GitOps |
|--------|-------------|---------------|
| **Deployment** | Manual/Ansible triggered | Git-triggered, automatic |
| **State Management** | Imperative | Declarative |
| **Rollbacks** | Manual helm rollback | Git revert + auto-sync |
| **Monitoring** | External tools | Built-in ArgoCD UI |
| **Secrets** | Ansible/manual | Git + sealed-secrets |
| **Multi-cluster** | Complex | Native support |

## 🎯 **Benefits After Migration**

- ✅ **GitOps**: All changes through Git PRs
- ✅ **Self-Healing**: Automatic drift detection and correction
- ✅ **Visibility**: ArgoCD UI shows real-time app status
- ✅ **Rollbacks**: Simple git reverts
- ✅ **Security**: Git-based audit trail
- ✅ **Scalability**: Easy multi-cluster management
