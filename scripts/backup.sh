#!/bin/bash
set -euo pipefail

# Backup script for CI/CD stack configuration and data
# Usage: ./backup.sh [backup-name]

BACKUP_NAME=${1:-"cluster-backup-$(date +%Y%m%d-%H%M%S)"}
BACKUP_DIR="./backups/$BACKUP_NAME"

echo "📦 Creating backup: $BACKUP_NAME"
echo "================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "🔧 Backing up Kubernetes resources..."

# Export all resources by namespace
for namespace in argocd longhorn-system cert-manager ingress metallb-system; do
    echo "  Backing up namespace: $namespace"
    mkdir -p "$BACKUP_DIR/namespaces/$namespace"
    
    # Export namespace-specific resources
    kubectl get all -n "$namespace" -o yaml > "$BACKUP_DIR/namespaces/$namespace/all-resources.yaml" 2>/dev/null || true
    kubectl get secrets -n "$namespace" -o yaml > "$BACKUP_DIR/namespaces/$namespace/secrets.yaml" 2>/dev/null || true
    kubectl get configmaps -n "$namespace" -o yaml > "$BACKUP_DIR/namespaces/$namespace/configmaps.yaml" 2>/dev/null || true
    kubectl get ingress -n "$namespace" -o yaml > "$BACKUP_DIR/namespaces/$namespace/ingress.yaml" 2>/dev/null || true
    kubectl get pvc -n "$namespace" -o yaml > "$BACKUP_DIR/namespaces/$namespace/pvc.yaml" 2>/dev/null || true
done

echo "📜 Backing up cluster-wide resources..."
mkdir -p "$BACKUP_DIR/cluster"

# Cluster-wide resources
kubectl get nodes -o yaml > "$BACKUP_DIR/cluster/nodes.yaml"
kubectl get storageclass -o yaml > "$BACKUP_DIR/cluster/storageclasses.yaml"
kubectl get clusterroles -o yaml > "$BACKUP_DIR/cluster/clusterroles.yaml"
kubectl get clusterrolebindings -o yaml > "$BACKUP_DIR/cluster/clusterrolebindings.yaml"
kubectl get certificates -A -o yaml > "$BACKUP_DIR/cluster/certificates.yaml" 2>/dev/null || true
kubectl get clusterissuers -o yaml > "$BACKUP_DIR/cluster/clusterissuers.yaml" 2>/dev/null || true

echo "🎯 Backing up Helm releases..."
mkdir -p "$BACKUP_DIR/helm"

# Export Helm release information
helm list -A -o yaml > "$BACKUP_DIR/helm/releases.yaml"

# Individual Helm values
for release in $(helm list -A --short); do
    namespace=$(helm list -A | grep "$release" | awk '{print $2}')
    echo "  Backing up Helm release: $release ($namespace)"
    helm get values "$release" -n "$namespace" > "$BACKUP_DIR/helm/${release}-values.yaml" 2>/dev/null || true
    helm get manifest "$release" -n "$namespace" > "$BACKUP_DIR/helm/${release}-manifest.yaml" 2>/dev/null || true
done

echo "📁 Backing up configuration files..."
mkdir -p "$BACKUP_DIR/config"

# Copy deployment configuration (adjust paths for actual structure)
cp -r ../stacks "$BACKUP_DIR/config/"
cp ../../infra/ansible/playbooks/stack_deployment.yml "$BACKUP_DIR/config/" 2>/dev/null || true
cp -r ../scripts "$BACKUP_DIR/config/" 2>/dev/null || true
cp ../*.md "$BACKUP_DIR/config/" 2>/dev/null || true

# Copy ansible configuration
mkdir -p "$BACKUP_DIR/config/ansible"
cp -r ../../infra/ansible/* "$BACKUP_DIR/config/ansible/" 2>/dev/null || true

echo "ℹ️  Creating backup information..."
cat > "$BACKUP_DIR/backup-info.txt" << EOF
Backup Information
==================
Created: $(date)
Backup Name: $BACKUP_NAME
Kubernetes Version: $(kubectl version --short --client)
Cluster: $(kubectl config current-context)

Helm Releases:
$(helm list -A)

Nodes:
$(kubectl get nodes)

Namespaces:
$(kubectl get namespaces)

Storage Classes:
$(kubectl get storageclass)

Persistent Volumes:
$(kubectl get pv)
EOF

echo "📊 Creating cluster health snapshot..."
if [ -f "./scripts/health-check.sh" ]; then
    ./scripts/health-check.sh > "$BACKUP_DIR/health-check-$(date +%Y%m%d-%H%M%S).log" 2>&1 || true
fi

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo ""
echo "✅ Backup completed successfully!"
echo "📍 Location: $BACKUP_DIR"
echo "📦 Size: $BACKUP_SIZE"
echo ""
echo "💾 Backup includes:"
echo "  - All Kubernetes resources"
echo "  - Helm releases and values"
echo "  - Configuration files"
echo "  - Cluster health snapshot"
echo ""
echo "🔄 To restore from this backup:"
echo "  1. Review backup-info.txt"
echo "  2. Restore configuration files to correct locations"
echo "  3. Run deployment: cd infra && ansible-playbook ansible/playbooks/stack_deployment.yml -e stack_file=../../../deployment/stacks/cicd-stack.yml -v"
echo "  4. Apply certificates: cd ../deployment && ./scripts/post-deployment.sh"
echo ""

# Cleanup old backups (keep last 5)
echo "🧹 Cleaning up old backups (keeping last 5)..."
ls -t ./backups/ 2>/dev/null | tail -n +6 | xargs -r rm -rf --

echo "🎉 Backup process completed!"
