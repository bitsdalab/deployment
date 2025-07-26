
#!/bin/bash
set -e

# Step 0: Vault Unseal Key Secret
echo ""
echo "🔑 Step 0: Vault Unseal Key Secret"
echo "==================================="

VAULT_NAMESPACE="vault"
VAULT_UNSEAL_SECRET="vault-unseal-secret"


# Prompt for Vault unseal keys if not set
if [[ -z "$VAULT_UNSEAL_KEY_1" ]]; then
    read -s -p "Unseal Key 1: " VAULT_UNSEAL_KEY_1; echo
fi
if [[ -z "$VAULT_UNSEAL_KEY_2" ]]; then
    read -s -p "Unseal Key 2: " VAULT_UNSEAL_KEY_2; echo
fi
if [[ -z "$VAULT_UNSEAL_KEY_3" ]]; then
    read -s -p "Unseal Key 3: " VAULT_UNSEAL_KEY_3; echo
fi
if [[ -z "$VAULT_UNSEAL_KEY_4" ]]; then
    read -s -p "Unseal Key 4: " VAULT_UNSEAL_KEY_4; echo
fi
if [[ -z "$VAULT_UNSEAL_KEY_5" ]]; then
    read -s -p "Unseal Key 5: " VAULT_UNSEAL_KEY_5; echo
fi
if [[ -z "$VAULT_UNSEAL_KEY" ]]; then
    read -s -p "Unseal Key: " VAULT_UNSEAL_KEY; echo
fi

echo "🔐 Configuring Vault unseal key secret with provided keys..."
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
echo "✅ Vault unseal key secret configured"

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

# Step 2: Apply ArgoCD Projects
echo ""
echo "📋 Step 2: Applying ArgoCD Projects (RBAC)"
echo "=========================================="

#setup ArgoCD projects
echo "Applying ArgoCD projects..."

kubectl apply -f argocd/projects/infrastructure.yaml
#kubectl apply -f argocd/projects/platform.yaml
#kubectl apply -f argocd/projects/workloads.yaml

echo "✅ ArgoCD Projects applied"

# Step 3: Apply Root Applications (AppSet and Applications)
echo ""
echo "📋 Step 3: Starting GitOps Bootstrap"
echo "==================================="

# Apply Applications root (deploys all Applications)
kubectl apply -f argocd/bootstrap/infrastructure-apps-root.yaml

# Apply ApplicationSet root (deploys all ApplicationSets)
kubectl apply -f argocd/bootstrap/infrastructure-appset-root.yaml


echo "✅ Infrastructure Applications and ApplicationSets created"