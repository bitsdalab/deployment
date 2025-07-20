#!/bin/bash
set -euo pipefail

# Post-deployment script to apply additional resources
# This script applies cluster issuers and copies wildcard certificates after cert-manager is ready

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager-webhook -n cert-manager
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager-cainjector -n cert-manager

echo "Applying cluster issuers and wildcard certificates..."
kubectl apply -f deployment/stacks/values/cert-manager/cluster-issuers.yaml

echo "Waiting for wildcard certificates to be ready..."
kubectl wait --for=condition=Ready --timeout=300s certificate/wildcard-app-bitsb-dev -n cert-manager
kubectl wait --for=condition=Ready --timeout=300s certificate/wildcard-cicd-bitsb-dev -n cert-manager

echo "Copying wildcard certificates to application namespaces..."

# Copy CI/CD wildcard cert to ArgoCD namespace
kubectl get secret wildcard-cicd-bitsb-dev-tls -n cert-manager -o yaml | \
  sed 's/namespace: cert-manager/namespace: argocd/' | \
  kubectl apply -f -

# Copy CI/CD wildcard cert to Longhorn namespace  
kubectl get secret wildcard-cicd-bitsb-dev-tls -n cert-manager -o yaml | \
  sed 's/namespace: cert-manager/namespace: longhorn-system/' | \
  kubectl apply -f -

# Copy CI/CD wildcard cert to Ingress namespace (for Kong)
kubectl get secret wildcard-cicd-bitsb-dev-tls -n cert-manager -o yaml | \
  sed 's/namespace: cert-manager/namespace: ingress/' | \
  kubectl apply -f -

# Copy App wildcard cert to Ingress namespace (for future apps)
kubectl get secret wildcard-app-bitsb-dev-tls -n cert-manager -o yaml | \
  sed 's/namespace: cert-manager/namespace: ingress/' | \
  kubectl apply -f -

echo "Post-deployment configuration completed successfully!"
