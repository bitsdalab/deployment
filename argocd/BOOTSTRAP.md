# GitOps Bootstrap with ArgoCD

## Quick Start

### 1. Prerequisites
- Kubernetes cluster with ArgoCD installed
- kubectl configured for your cluster
- Git repository access to https://github.com/bitsdalab/infra

### 2. Bootstrap Process

#### Option A: Automated Bootstrap (Recommended)
```bash
# Run the bootstrap script
./deployment/argocd/bootstrap.sh
```

#### Option B: Manual Bootstrap
```bash
# Step 1: Setup Repository Access (for private repos)
kubectl create secret generic bitsdalab-infra-repo \
  --namespace=argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/bitsdalab/infra \
  --from-literal=username=<github-username> \
  --from-literal=password=<github-token>

kubectl label secret bitsdalab-infra-repo \
  --namespace=argocd \
  argocd.argoproj.io/secret-type=repository

# Step 2: Apply ArgoCD Projects (RBAC)
kubectl apply -f deployment/argocd/projects/

# Step 3: Apply Root Application (App-of-Apps)
kubectl apply -f deployment/argocd/bootstrap/root-app.yaml

# Step 4: Watch the magic happen!
kubectl get applications -n argocd
argocd app list
```

### 3. Deployment Flow

```
Root App (bootstrap/root-app.yaml)
├── Infrastructure App → Infrastructure ApplicationSet
│   ├── MetalLB (sync-wave: 1)
│   ├── cert-manager (sync-wave: 2) + Root CA setup
│   ├── Kong (sync-wave: 3)
│   └── Longhorn (sync-wave: 4) + deps installation
├── Platform App → Platform ApplicationSet
│   └── ArgoCD (sync-wave: 1)
└── Workloads App → Workloads ApplicationSet
    └── (Future applications)
```

### 4. What Gets Deployed

**Infrastructure (sync order)**:
1. **MetalLB**: LoadBalancer with IP pool (192.168.1.240-250)
2. **cert-manager**: TLS certificates + Root CA for bitsb.dev
3. **Kong**: Ingress controller with HTTPS redirect
4. **Longhorn**: Distributed storage (with automatic open-iscsi installation)

**Platform**:
1. **ArgoCD**: GitOps platform with ingress at `argocd.cicd.bitsb.dev`

### 5. Verification

```bash
# Check all applications
kubectl get applications -n argocd

# Check infrastructure
kubectl get svc -n metallb-system
kubectl get certificates -A
kubectl get ingress -A
kubectl get storageclass

# Check platform
kubectl get pods -n argocd
curl https://argocd.cicd.bitsb.dev
```

### 6. Adding New Applications

**For Infrastructure**: Add to `appsets/infrastructure/infrastructure-appset.yaml`
**For Platform**: Add to `appsets/platform/platform-appset.yaml`
**For Workloads**: Create `appsets/workloads/workloads-appset.yaml`

Then create the corresponding application manifest in `applications/{type}/{name}/`

### 7. Root CA Trust

The system automatically creates a root CA for `*.bitsb.dev`. To trust it in browsers:

1. Get the CA certificate: `kubectl get secret bitsb-root-ca -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > bitsb-ca.crt`
2. Import `bitsb-ca.crt` into your browser/system trust store

## Benefits of This Approach

✅ **Fully Declarative**: Everything in Git
✅ **Self-Healing**: ArgoCD ensures desired state
✅ **Ordered Deployment**: Sync waves ensure proper dependency order
✅ **Pre/Post Hooks**: Automated dependency installation and configuration
✅ **RBAC**: Project-based access control
✅ **Scalable**: ApplicationSets manage similar applications
✅ **Production Ready**: Root CA, ingress, storage, load balancing
