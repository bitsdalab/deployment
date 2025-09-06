# External Secrets Operator - Vault Integration

## Setup

Create Vault root token secret:

```bash
# Get your Vault root token
kubectl exec -n vault vault-0 -- cat /vault/data/keys.json | jq -r '.root_token'

# Create the secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-root-token
  namespace: external-secrets
type: Opaque
stringData:
  token: "YOUR_ACTUAL_VAULT_ROOT_TOKEN_HERE"
EOF
```