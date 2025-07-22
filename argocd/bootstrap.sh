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

# Create repository secret with credentials if available
PROJECT="default"  # Set your ArgoCD project name here
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

# Step 3: Apply Root Application
echo ""
echo "📋 Step 3: Starting GitOps Bootstrap"
echo "==================================="

#kubectl apply -f argocd/bootstrap/root-app.yaml
kubectl apply -f argocd/bootstrap/infrastructure-app.yaml

echo "✅ Infrastructure Application created"

# Step 4: Wait and verify
echo ""
echo "📋 Step 4: Verification"
echo "======================"

echo "⏳ Waiting for applications to appear..."
sleep 15

echo "📊 Current Applications:"
kubectl get applications -n $ARGOCD_NAMESPACE

echo ""
echo "🎉 Bootstrap Complete!"
echo "====================="
echo ""
echo "🔗 Access Points:"
echo "  ArgoCD UI: https://argocd.cicd.bitsb.dev"
echo "  ArgoCD Admin Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "📝 What's Happening:"
echo "  1. ArgoCD is deploying infrastructure components (MetalLB, cert-manager, Kong, Longhorn)"
echo "  2. Root CA will be created automatically for *.bitsb.dev"
echo "  3. LoadBalancer IPs will be assigned from 192.168.1.240-250"
echo "  4. All services will have automatic HTTPS certificates"
echo ""
echo "⏳ Deployment Progress:"
echo "  Watch: kubectl get applications -n argocd -w"
echo "  Pods:  kubectl get pods -A"
echo "  Services: kubectl get svc -A -o wide | grep LoadBalancer"
echo ""
echo "🔍 Useful Commands:"
echo "  kubectl get applications -n argocd"
echo "  kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller"
echo ""
echo "🎯 Development Workflow:"
echo "  1. Edit values in stacks/values/"
echo "  2. Commit and push to Git"
echo "  3. ArgoCD automatically syncs changes"
echo "  4. View changes in ArgoCD UI"
