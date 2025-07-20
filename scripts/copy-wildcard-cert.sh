#!/bin/bash
set -euo pipefail

# Script to copy wildcard certificates to a target namespace
# Usage: ./copy-wildcard-cert.sh <cert-type> <target-namespace>
# cert-type: "app" for *.bitsb.dev or "cicd" for *.cicd.bitsb.dev

if [ $# -ne 2 ]; then
    echo "Usage: $0 <cert-type> <target-namespace>"
    echo "cert-type: 'app' for *.bitsb.dev or 'cicd' for *.cicd.bitsb.dev"
    echo "Example: $0 cicd harbor"
    exit 1
fi

CERT_TYPE="$1"
TARGET_NAMESPACE="$2"

case "$CERT_TYPE" in
    "app")
        SECRET_NAME="wildcard-app-bitsb-dev-tls"
        ;;
    "cicd")
        SECRET_NAME="wildcard-cicd-bitsb-dev-tls"
        ;;
    *)
        echo "Error: cert-type must be 'app' or 'cicd'"
        exit 1
        ;;
esac

echo "Copying $SECRET_NAME to namespace $TARGET_NAMESPACE..."

# Create target namespace if it doesn't exist
kubectl create namespace "$TARGET_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Copy the secret
kubectl get secret "$SECRET_NAME" -n cert-manager -o yaml | \
  sed "s/namespace: cert-manager/namespace: $TARGET_NAMESPACE/" | \
  kubectl apply -f -

echo "Successfully copied $SECRET_NAME to $TARGET_NAMESPACE namespace!"
