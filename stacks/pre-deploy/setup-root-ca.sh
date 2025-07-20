#!/bin/bash
set -e

echo "🔐 Setting up Root CA for bitsb.dev domain..."

# Function to create ClusterIssuer
create_cluster_issuer() {
    echo "🗂️ Creating ClusterIssuer for Root CA..."
    
    # Create ClusterIssuer that uses the Root CA
    cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: bitsb-root-ca-issuer
  labels:
    app.kubernetes.io/managed-by: bitsb-automation
spec:
  ca:
    secretName: bitsb-root-ca
EOF
}

# Check if root CA secret already exists
if kubectl get secret bitsb-root-ca -n cert-manager >/dev/null 2>&1; then
    echo "✅ Root CA secret 'bitsb-root-ca' already exists in cert-manager namespace"
    
    # Also check if ClusterIssuer exists
    if kubectl get clusterissuer bitsb-root-ca-issuer >/dev/null 2>&1; then
        echo "✅ ClusterIssuer 'bitsb-root-ca-issuer' already exists"
        echo "🎉 Root CA setup is already complete!"
        exit 0
    else
        echo "⚠️  Secret exists but ClusterIssuer missing. Creating ClusterIssuer..."
        create_cluster_issuer
        echo "🎉 Root CA setup completed!"
        exit 0
    fi
else
    echo "📜 Creating Root CA certificate and private key..."
fi

# Create temporary directory for certificate generation
CERT_DIR="/tmp/bitsb-ca-$(date +%s)"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# Generate Root CA private key
openssl genrsa -out ca.key 4096

# Create Root CA certificate
cat > ca.conf << EOF
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
C = US
ST = California
L = San Francisco
O = BitSB Development
OU = Infrastructure
CN = BitSB Root CA
emailAddress = admin@bitsb.dev

[ v3_ca ]
basicConstraints = critical,CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

# Generate Root CA certificate (valid for 10 years)
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -config ca.conf -extensions v3_ca

echo "🔍 Root CA Certificate Information:"
openssl x509 -in ca.crt -text -noout | grep -E "(Subject|Validity|CN|DNS)"

echo "🔧 Creating Kubernetes secret for Root CA..."

# Create cert-manager namespace if it doesn't exist
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Create the Root CA secret in cert-manager namespace
kubectl create secret tls bitsb-root-ca \
    --cert=ca.crt \
    --key=ca.key \
    -n cert-manager

# Label the secret for cert-manager
kubectl label secret bitsb-root-ca -n cert-manager \
    cert-manager.io/root-ca=true \
    app.kubernetes.io/managed-by=bitsb-automation

# Create the ClusterIssuer
create_cluster_issuer

echo "🧪 Testing certificate issuance..."

# Create a test certificate to verify the CA works
cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bitsb-ca-test
  namespace: cert-manager
  labels:
    app.kubernetes.io/managed-by: bitsb-automation
spec:
  secretName: bitsb-ca-test-tls
  issuerRef:
    name: bitsb-root-ca-issuer
    kind: ClusterIssuer
  commonName: test.bitsb.dev
  dnsNames:
  - test.bitsb.dev
  - "*.bitsb.dev"
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days
EOF

echo "⏳ Waiting for test certificate to be issued..."
sleep 5

# Wait for certificate to be ready (with timeout)
if kubectl wait --for=condition=ready certificate/bitsb-ca-test -n cert-manager --timeout=60s; then
    echo "✅ Test certificate issued successfully!"
    
    # Show certificate details
    echo "🔍 Test Certificate Details:"
    kubectl get certificate bitsb-ca-test -n cert-manager -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'
    echo ""
else
    echo "❌ Test certificate failed to issue. Check cert-manager logs:"
    kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager --tail=20
fi

# Cleanup test certificate
echo "🧹 Cleaning up test certificate..."
kubectl delete certificate bitsb-ca-test -n cert-manager --ignore-not-found=true
kubectl delete secret bitsb-ca-test-tls -n cert-manager --ignore-not-found=true

# Cleanup temporary files
cd /
rm -rf "$CERT_DIR"

echo "🎉 Root CA setup completed!"
echo ""
echo "📋 Summary:"
echo "  - Root CA Secret: bitsb-root-ca (cert-manager namespace)"
echo "  - ClusterIssuer: bitsb-root-ca-issuer"
echo "  - CA Subject: CN=BitSB Root CA, O=BitSB Development"
echo ""
echo "🔧 To use this CA in your applications:"
echo "  cert-manager.io/cluster-issuer: \"bitsb-root-ca-issuer\""
echo ""
echo "⚠️  Remember to:"
echo "  1. Distribute ca.crt to client systems that need to trust it"
echo "  2. Update ingress annotations to use bitsb-root-ca-issuer"
echo "  3. Consider setting up automatic CA distribution for development"
