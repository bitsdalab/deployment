# ArgoCD GitOps Structure

## Overview
This directory contains ArgoCD Applications and ApplicationSets for managing the entire Kubernetes platform using GitOps principles.

## Directory Structure
```
argocd/
├── bootstrap/                    # Bootstrap Applications (App-of-Apps)
│   ├── root-app.yaml            # Root application that manages everything
│   ├── infrastructure-app.yaml  # Manages infrastructure ApplicationSets
│   ├── platform-app.yaml       # Manages platform services ApplicationSets
│   └── workloads-app.yaml      # Manages application workloads ApplicationSets
├── appsets/                     # ApplicationSets for managing multiple apps
│   ├── infrastructure/         # Core infrastructure (MetalLB, cert-manager, etc.)
│   ├── platform/              # Platform services (ArgoCD, monitoring, etc.)
│   └── workloads/             # Application workloads (microservices, apps)
├── applications/              # Individual Application manifests
│   ├── infrastructure/
│   ├── platform/
│   └── workloads/
└── projects/                 # ArgoCD Projects for RBAC and organization
    ├── infrastructure.yaml
    ├── platform.yaml
    └── workloads.yaml
```

## Bootstrap Process
1. Apply ArgoCD Projects for RBAC
2. Apply Root Application (App-of-Apps)
3. Root App manages all other ApplicationSets and Applications
4. ApplicationSets automatically manage individual applications

## Deployment Flow
```
Root App
├── Infrastructure App → Infrastructure ApplicationSet → Individual Infrastructure Apps
├── Platform App → Platform ApplicationSet → Individual Platform Apps
└── Workloads App → Workloads ApplicationSet → Individual Workload Apps
```

## Usage

### Initial Bootstrap
```bash
# Apply ArgoCD Projects first
kubectl apply -f argocd/projects/

# Apply the root application (starts everything)
kubectl apply -f argocd/bootstrap/root-app.yaml
```

### Adding New Applications
1. Add Helm chart values to appropriate `deployment/stacks/values/` directory
2. ApplicationSets will automatically detect and create Applications
3. ArgoCD syncs changes automatically

## Benefits
- **Declarative**: Everything managed through Git
- **Self-Healing**: ArgoCD automatically syncs desired state
- **Progressive Deployment**: Infrastructure → Platform → Workloads
- **RBAC**: Project-based permissions and isolation
- **Scalable**: ApplicationSets manage multiple similar applications
