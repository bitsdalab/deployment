
#!/bin/bash
set -e

# Step 0: Vault Unseal Key Secret
# WARNING: This is for development/testing only!
# In production, Vault should be manually unsealed for security.
# Consider using Vault Auto-unseal with cloud KMS (AWS KMS, Azure Key Vault, etc.)
# or implement proper key management with multiple unseal keys and threshold.
echo ""
echo "🔑 Step 0: Vault Unseal Key Secret (DEV ONLY)"
echo "=============================================="

VAULT_NAMESPACE="vault"
VAULT_UNSEAL_SECRET="vault-unseal-secret"

# Check if Vault unseal key is set, prompt if not
if [[ -z "$VAULT_UNSEAL_KEY" ]]; then
    read -s -p "Vault Unseal Key (DEV ONLY): " VAULT_UNSEAL_KEY; echo
fi

echo "🔐 Configuring Vault unseal key secret (DEV ONLY)..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $VAULT_UNSEAL_SECRET
  namespace: $VAULT_NAMESPACE
  labels:
    app.kubernetes.io/name: vault
    app.kubernetes.io/part-of: infrastructure
type: Opaque
stringData:
  key: $VAULT_UNSEAL_KEY
EOF
echo "✅ Vault unseal key secret configured (DEV ONLY)"

echo "🚀 Bootstrapping ArgoCD GitOps Platform (Development)"
echo "====================================================="

# Configuration
GITHUB_REPO="https://github.com/bitsdalab/deployment.git"
ARGOCD_NAMESPACE="argocd"

# Step 1: Repository Access with credentials
echo ""
echo "📋 Step 1: Repository Access Setup"
echo "=================================="

# Prompt for GitHub credentials if not set
if [[ -z "$GITHUB_USERNAME" ]]; then
    read -p "GitHub Username: " GITHUB_USERNAME
    export GITHUB_USERNAME
fi
if [[ -z "$GITHUB_TOKEN" ]]; then
    read -s -p "GitHub Token (will not echo): " GITHUB_TOKEN
    echo
    export GITHUB_TOKEN
fi

echo "🔐 Configuring repository access with provided credentials..."

PROJECT="infrastructure"  # Set your ArgoCD project name here
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: bitsdalab-deployment-repo
  namespace: $ARGOCD_NAMESPACE
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: $GITHUB_REPO
  project: $PROJECT
${GITHUB_USERNAME:+  username: $GITHUB_USERNAME}
${GITHUB_TOKEN:+  password: $GITHUB_TOKEN}
EOF

echo "✅ Repository access configured"

PROJECT="observability"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: bitsdalab-deployment-repo-observability
  namespace: $ARGOCD_NAMESPACE
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: $GITHUB_REPO
  project: $PROJECT
${GITHUB_USERNAME:+  username: $GITHUB_USERNAME}
${GITHUB_TOKEN:+  password: $GITHUB_TOKEN}
EOF

echo "✅ Repository access for observability configured"

# Step 2: Apply ArgoCD Projects
echo ""
echo "📋 Step 2: Applying ArgoCD Projects (RBAC)"
echo "=========================================="

echo "🔧 Applying ArgoCD projects..."

# Apply all ArgoCD projects from directory
kubectl apply -f argocd/projects/

echo "✅ ArgoCD Projects applied"

# Step 3: Apply Root Applications (AppSet and Applications)
echo ""
echo "📋 Step 3: Starting GitOps Bootstrap"
echo "==================================="

echo "🚀 Applying bootstrap applications..."

# Apply all bootstrap configurations from directory
kubectl apply -f argocd/bootstrap/

echo "✅ All ApplicationSets and Applications created"

echo "🎉 Bootstrap Complete! Your GitOps platform is deploying..."
echo "💡 Monitor deployment: kubectl get applications -n argocd -w"