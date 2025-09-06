# Outline OIDC Setup

## Authentik Configuration

Configure Authentik OIDC provider with redirect URI:
```
https://outline.cicd.bitsb.dev/auth/oidc.callback
```

## Vault Secret

Create this secret in Vault at `operations/outline/authentik`:

```json
{
  "client_id": "your-authentik-client-id",
  "client_secret": "your-authentik-client-secret", 
  "auth_uri": "https://auth.bitsb.dev/application/o/authorize/",
  "token_uri": "https://auth.bitsb.dev/application/o/token/",
  "userinfo_uri": "https://auth.bitsb.dev/application/o/userinfo/"
}
```

## Apply

```bash
kubectl apply -f outline-external-secret.yaml
```

The ExternalSecret will create `outline-auth-secret` with OIDC environment variables for Outline.
