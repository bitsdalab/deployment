#!/bin/bash
set -e

echo "🚀 Bootstrapping ArgoCD GitOps Platform (Development)"
echo "====================================================="

# Configuration
GITHUB_REPO="https://github.com/bitsdalab/deployment.git"
ARGOCD_NAMESPACE="argocd"

# Step 1: Repository Access with credentials
echo ""
echo "📋 Step 1: Repository Access Setup"
echo "=================================="

# Check if credentials are provided
if [[ -z "$GITHUB_USERNAME" || -z "$GITHUB_TOKEN" ]]; then
    echo "⚠️  GitHub credentials not provided in environment variables"
    echo "   Please set GITHUB_USERNAME and GITHUB_TOKEN:"
    echo "   export GITHUB_USERNAME=bits176"
    echo "   export GITHUB_TOKEN=ghp_your_token_here"
    echo ""
    echo "🔒 Using current cluster credentials (if any)..."
else
    echo "🔐 Configuring repository access with provided credentials..."
fi

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

# Apply ApplicationSet root (deploys all ApplicationSets)
kubectl apply -f argocd/bootstrap/infrastructure-appset-root.yaml
# Apply Applications root (deploys all Applications)
kubectl apply -f argocd/bootstrap/infrastructure-apps-root.yaml

echo "✅ Infrastructure Applications and ApplicationSets created"