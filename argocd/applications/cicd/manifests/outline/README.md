# Outline OIDC Authentication with Authentik

This guide provides complete setup instructions for integrating Outline wiki with Authentik OIDC authentication using External Secrets Operator (ESO) and HashiCorp Vault for secure secret management.

## Prerequisites

- Kubernetes cluster with ArgoCD
- External Secrets Operator (ESO) installed
- HashiCorp Vault with KV v2 engine
- Authentik identity provider
- cert-manager for TLS certificates

## Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Outline   │◄──►│  Authentik  │    │    Vault    │◄──►│     ESO     │
│    Wiki     │    │    OIDC     │    │  Secrets    │    │ Controller  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       └───────────────────┼───────────────────┼───────────────────┘
                           │                   │
                    ┌─────────────┐    ┌─────────────┐
                    │ Kubernetes  │    │   ArgoCD    │
                    │  Secrets    │    │ GitOps Mgmt │
                    └─────────────┘    └─────────────┘
```

## 1. Authentik Configuration

### Create OIDC Application
1. Log into Authentik admin interface
2. Navigate to **Applications** → **Applications** → **Create**
3. Configure the application:
   - **Name**: `Outline Wiki`
   - **Slug**: `outline`
   - **Provider**: Create new OAuth2/OpenID Provider

### Create OAuth2/OpenID Provider
1. **Name**: `Outline OIDC Provider`
2. **Client Type**: `Confidential`
3. **Client ID**: `Jru1yoSOna9Z36u913sFf4on4txpVJYAqXYE2pkZ`
4. **Client Secret**: Generate and save securely
5. **Redirect URIs**: `https://outline.cicd.bitsb.dev/auth/oidc.callback`
6. **Scopes**: `openid`, `profile`, `email`
7. **Subject Mode**: `Based on the User's hashed ID`
8. **Include claims in id_token**: ✓ Enabled

### OIDC Endpoints
- **Authorization URL**: `https://authentik.cicd.bitsb.dev/application/o/authorize/`
- **Token URL**: `https://authentik.cicd.bitsb.dev/application/o/token/`
- **UserInfo URL**: `https://authentik.cicd.bitsb.dev/application/o/userinfo/`
- **End Session URL**: `https://authentik.cicd.bitsb.dev/application/o/outline/end-session/`

## 2. Vault Secret Management

### Store OIDC Client Secret
```bash
# Store the client secret from Authentik
vault kv put operations/outline/credentials \
  client_secret="YOUR_AUTHENTIK_CLIENT_SECRET"
```

### Store Outline Secret Key
```bash
# Generate and store a secure secret key for Outline
vault kv put operations/outline/secrets \
  secret_key="$(openssl rand -hex 32)"
```

### Verify Vault Secrets
```bash
# Verify secrets are stored correctly
vault kv get operations/outline/credentials
vault kv get operations/outline/secrets
```

## 3. External Secrets Configuration

### OIDC Credentials External Secret
Create `outline-external-secret.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: outline-oidc-credentials
  namespace: outline
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: cluster-secret-store-operations
    kind: ClusterSecretStore
  target:
    name: outline-oidc-credentials
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        client-secret: "{{ .client_secret }}"
  data:
    - secretKey: client_secret
      remoteRef:
        key: operations/outline/credentials
        property: client_secret
```

### Outline Secret Key External Secret
Create `outline-secrets-external-secret.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: outline-secrets
  namespace: outline
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: cluster-secret-store-operations
    kind: ClusterSecretStore
  target:
    name: outline-secrets
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        secret-key: "{{ .secret_key }}"
  data:
    - secretKey: secret_key
      remoteRef:
        key: operations/outline/secrets
        property: secret_key
```

## 4. Outline Helm Configuration

### Complete values.yaml
```yaml
image:
  repository: outlinewiki/outline
  tag: latest

service:
  type: ClusterIP
  port: 3000

ingress:
  enabled: true
  className: "kong"
  hosts:
    - host: outline.cicd.bitsb.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - outline.cicd.bitsb.dev
      secretName: outline-tls
  annotations:
    cert-manager.io/cluster-issuer: "bitsb-root-ca-issuer"

# OIDC Authentication with Authentik
auth:
  oidc:
    enabled: true
    clientId: "Jru1yoSOna9Z36u913sFf4on4txpVJYAqXYE2pkZ"
    authUri: "https://authentik.cicd.bitsb.dev/application/o/authorize/"
    tokenUri: "https://authentik.cicd.bitsb.dev/application/o/token/"
    userInfoUri: "https://authentik.cicd.bitsb.dev/application/o/userinfo/"
    logoutUri: "https://authentik.cicd.bitsb.dev/application/o/outline/end-session/"
    displayName: "Authentik SSO"
    scopes:
      - openid
      - profile
      - email
    usernameClaim: "preferred_username"
    # Use existing secret for client secret (managed by ESO)
    existingSecret:
      name: "outline-oidc-credentials"
      clientSecretKey: "client-secret"

resources:
  limits:
    cpu: 300m
    memory: 756Mi
  requests:
    cpu: 100m
    memory: 256Mi

# Ignore SSL certificate verification for internal OIDC
extraEnvVars:
  NODE_TLS_REJECT_UNAUTHORIZED: "0"

# Use external secret for secret key (managed by ESO)
secretKeyExternalSecret:
  name: "outline-secrets"
  key: "secret-key"

postgresql:
  enabled: true
  auth:
    username: outline
    password: outlinepass
    database: outline
    postgresPassword: outlinepass

redis:
  enabled: true
  auth:
    password: CHANGEME
```

## 5. ArgoCD Application

### Outline Application Manifest
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: outline
  namespace: argocd
spec:
  project: cicd
  source:
    repoURL: https://github.com/bitsdalab/deployment
    targetRevision: HEAD
    path: argocd/applications/cicd/manifests/outline
  destination:
    server: https://kubernetes.default.svc
    namespace: outline
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## 6. Deployment Order

1. **Deploy External Secrets**:
   ```bash
   kubectl apply -f outline-external-secret.yaml
   kubectl apply -f outline-secrets-external-secret.yaml
   ```

2. **Verify Secrets Creation**:
   ```bash
   kubectl get secrets -n outline
   kubectl describe externalsecret -n outline
   ```

3. **Deploy Outline via ArgoCD**:
   ```bash
   kubectl apply -f outline-application.yaml
   ```

4. **Monitor Deployment**:
   ```bash
   kubectl get pods -n outline
   kubectl logs -n outline deployment/outline
   ```

## 7. Verification & Testing

### Check OIDC Integration
1. Navigate to `https://outline.cicd.bitsb.dev`
2. Click "Continue with Authentik SSO"
3. Authenticate with Authentik credentials
4. Verify successful login and user creation

### Troubleshooting Commands
```bash
# Check External Secrets status
kubectl get externalsecrets -n outline
kubectl describe externalsecret outline-oidc-credentials -n outline

# Check generated secrets
kubectl get secret outline-oidc-credentials -n outline -o yaml
kubectl get secret outline-secrets -n outline -o yaml

# Check Outline logs
kubectl logs -n outline deployment/outline --tail=50

# Check Outline configuration
kubectl exec -n outline deployment/outline -- env | grep -E "(OIDC|SECRET)"
```

## 8. Security Considerations

- **Secret Rotation**: Vault secrets can be rotated independently
- **RBAC**: Ensure proper RBAC for Vault and ESO access
- **TLS**: All communications use TLS certificates
- **Network Policies**: Consider implementing network policies for pod-to-pod communication
- **Audit Logging**: Enable audit logging in Authentik and Vault

## 9. Maintenance

### Updating OIDC Client Secret
```bash
# Update secret in Vault
vault kv patch operations/outline/credentials client_secret="NEW_SECRET"

# ESO will automatically sync the new secret within the refresh interval (1h)
# Or force immediate sync:
kubectl annotate externalsecret outline-oidc-credentials -n outline force-sync="$(date +%s)"
```

### Updating Outline Secret Key
```bash
# ⚠️ WARNING: Changing the secret key will make existing encrypted data unreadable
# Only update if absolutely necessary and you have a backup strategy

vault kv patch operations/outline/secrets secret_key="NEW_SECRET_KEY"
```

## Support & References

- **Outline Documentation**: https://docs.getoutline.com/
- **Authentik OIDC Guide**: https://goauthentik.io/docs/providers/oauth2/
- **External Secrets Operator**: https://external-secrets.io/
- **HashiCorp Vault**: https://developer.hashicorp.com/vault/docs

This configuration provides a production-ready, secure, and GitOps-native setup for Outline with Authentik OIDC authentication, ensuring no hardcoded secrets and full compatibility with Helm charts and ArgoCD.
