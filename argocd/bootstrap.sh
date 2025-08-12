
#!/bin/bash
set -e

# Step 0: Vault Unseal Key Secret
echo ""
echo "🔑 Step 0: Vault Unseal Key Secret"
echo "==================================="

VAULT_NAMESPACE="vault"
VAULT_UNSEAL_SECRET="vault-unseal-secret"

# Check if Vault unseal key is set, prompt if not
if [[ -z "$VAULT_UNSEAL_KEY" ]]; then
    read -s -p "Vault Unseal Key: " VAULT_UNSEAL_KEY; echo
fi

echo "🔐 Configuring Vault unseal key secret..."
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

# Apply ArgoCD projects
kubectl apply -f argocd/projects/infrastructure.yaml
kubectl apply -f argocd/projects/cicd.yaml
kubectl apply -f argocd/projects/observability.yaml
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
kubectl apply -f argocd/bootstrap/observability-appset-root.yaml

echo "✅ Infrastructure Applications and ApplicationSets created"

# Step 4: Deploy CICD Platform
echo ""
echo "📋 Step 4: Deploying CICD Platform"
echo "=================================="

# Apply CICD ApplicationSet root (deploys Authentik, Harbor, Jenkins)
kubectl apply -f argocd/bootstrap/cicd-appset-root.yaml

echo "✅ CICD Platform ApplicationSet created"

# Step 5: Display Access Information
echo ""
echo "🌐 Step 5: Access Information"
echo "============================"

echo ""
echo "📝 Add these domains to your /etc/hosts:"
echo "----------------------------------------"
echo "# Replace <CLUSTER_IP> with your actual cluster IP"
echo "<CLUSTER_IP>    argocd.cicd.bitsb.dev"
echo "<CLUSTER_IP>    longhorn.cicd.bitsb.dev"
echo "<CLUSTER_IP>    vault.cicd.bitsb.dev"
echo "<CLUSTER_IP>    authentik.cicd.bitsb.dev"
echo "<CLUSTER_IP>    harbor.cicd.bitsb.dev"
echo "<CLUSTER_IP>    jenkins.cicd.bitsb.dev"
echo "<CLUSTER_IP>    grafana.ops.bitsb.dev"
echo "<CLUSTER_IP>    thanos.ops.bitsb.dev"
echo ""

echo "🔍 Find your cluster IP with:"
echo "kubectl get svc -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""

echo "🔐 Default Credentials:"
echo "----------------------"
echo "Harbor:   https://harbor.cicd.bitsb.dev (admin / Harbor12345)"
echo "Jenkins:  https://jenkins.cicd.bitsb.dev (admin / admin123)"
echo "Authentik: https://authentik.cicd.bitsb.dev (setup required on first access)"
echo ""

echo "🎉 Bootstrap Complete! Your GitOps platform is deploying..."
echo "💡 Monitor deployment: kubectl get applications -n argocd -w"