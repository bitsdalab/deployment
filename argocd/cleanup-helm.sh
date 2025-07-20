#!/bin/bash
set -e

echo "🧹 Cleaning Up Classic Helm Deployments for GitOps Migration"
echo "============================================================"

echo "📋 Checking existing Helm releases..."
helm list -A

echo ""
echo "⚠️  WARNING: This will remove existing Helm-managed applications!"
echo "   ArgoCD will then redeploy them using GitOps."
echo ""
read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🔍 Step 1: Identifying Infrastructure Components"
echo "=============================================="

# Infrastructure components that should be managed by ArgoCD
# NOTE: Excluding ArgoCD itself since we want to keep the existing installation
INFRASTRUCTURE_RELEASES=(
    "metallb:metallb-system"
    "cert-manager:cert-manager" 
    "kong:ingress"
    "longhorn:longhorn-system"
)

echo "Infrastructure releases to remove:"
for release_info in "${INFRASTRUCTURE_RELEASES[@]}"; do
    release_name=$(echo $release_info | cut -d':' -f1)
    namespace=$(echo $release_info | cut -d':' -f2)
    
    if helm list -n $namespace | grep -q $release_name; then
        echo "  ✓ Found: $release_name (namespace: $namespace)"
    else
        echo "  - Not found: $release_name (namespace: $namespace)"
    fi
done

echo ""
echo "🗑️  Step 2: Removing Helm Releases"
echo "================================="

for release_info in "${INFRASTRUCTURE_RELEASES[@]}"; do
    release_name=$(echo $release_info | cut -d':' -f1)
    namespace=$(echo $release_info | cut -d':' -f2)
    
    if helm list -n $namespace | grep -q $release_name; then
        echo "🔄 Removing Helm release: $release_name from namespace $namespace..."
        helm uninstall $release_name -n $namespace
        echo "✅ Removed: $release_name"
    else
        echo "ℹ️  Release not found: $release_name"
    fi
done

echo ""
echo "🧹 Step 3: Cleaning Up Resources (Optional)"
echo "=========================================="

echo "The following resources might need manual cleanup:"
echo ""

# Check for PVCs (especially for Longhorn)
echo "📊 Persistent Volume Claims:"
kubectl get pvc -A | grep -E "(longhorn|metallb|cert-manager|kong|argocd)" || echo "  No PVCs found"

echo ""
echo "📊 Persistent Volumes:"
kubectl get pv | grep -E "(longhorn|local)" || echo "  No PVs found"

echo ""
echo "📊 Storage Classes:"
kubectl get storageclass | grep -E "(longhorn|local)" || echo "  No custom storage classes found"

echo ""
echo "📊 Custom Resources (CRDs that might remain):"
kubectl get crd | grep -E "(metallb|cert-manager|kong|longhorn)" || echo "  No custom CRDs found"

echo ""
echo "⚠️  Optional Cleanup Commands:"
echo "   # Remove Longhorn PVs and data (DESTRUCTIVE!):"
echo "   kubectl delete pv --all"
echo "   kubectl delete storageclass longhorn"
echo ""
echo "   # Remove cert-manager CRDs:"
echo "   kubectl delete crd \$(kubectl get crd | grep cert-manager | awk '{print \$1}')"
echo ""
echo "   # Remove MetalLB CRDs:"
echo "   kubectl delete crd \$(kubectl get crd | grep metallb | awk '{print \$1}')"

echo ""
echo "🎉 Helm Cleanup Complete!"
echo "======================="
echo ""
echo "📋 Next Steps:"
echo "  1. Run ArgoCD bootstrap: ./argocd/bootstrap.sh"
echo "  2. Wait for ArgoCD to redeploy applications"
echo "  3. Verify all services are working"
echo ""
echo "🔍 Verify cleanup with:"
echo "  helm list -A"
echo "  kubectl get applications -n argocd"
