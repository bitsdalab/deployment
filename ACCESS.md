# Platform Access Information

## 🌐 Service Endpoints

Add these domains to your `/etc/hosts` file:
```bash
# Replace <CLUSTER_IP> with your actual cluster IP

# Infrastructure Services
<CLUSTER_IP>    longhorn.ops.bitsb.dev
<CLUSTER_IP>    vault.ops.bitsb.dev

# CI/CD Services
<CLUSTER_IP>    argocd.cicd.bitsb.dev
<CLUSTER_IP>    authentik.cicd.bitsb.dev
<CLUSTER_IP>    harbor.cicd.bitsb.dev
<CLUSTER_IP>    jenkins.cicd.bitsb.dev

# Observability Services
<CLUSTER_IP>    signoz.ops.bitsb.dev
<CLUSTER_IP>    grafana.ops.bitsb.dev
```

## 🔍 Find Your Cluster IP
```bash
kubectl get svc -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## 🔐 Default Credentials

### 📦 Infrastructure
- **Vault**: https://vault.ops.bitsb.dev (setup required)
- **Longhorn**: https://longhorn.ops.bitsb.dev (no auth by default)

### 🔨 CI/CD
- **ArgoCD**: https://argocd.cicd.bitsb.dev (admin / get from secret)
- **Harbor**: https://harbor.cicd.bitsb.dev (admin / Harbor12345)
- **Jenkins**: https://jenkins.cicd.bitsb.dev (admin / admin123)
- **Authentik**: https://authentik.cicd.bitsb.dev (setup required)

### 📊 Observability
- **SigNoz**: https://signoz.ops.bitsb.dev (no auth by default)
- **Grafana**: https://grafana.ops.bitsb.dev (admin / admin)

## 🛠️ Useful Commands

### Monitor ArgoCD Applications
```bash
kubectl get applications -n argocd -w
```

### Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Check Service Status
```bash
kubectl get pods -A
kubectl get ingress -A
```
