# Stack Deployment Values Structure

This directory contains Helm values files for each application in our CI/CD stack.

## Directory Structure

```
deployment/stacks/
├── cicd-stack.yml           # Main stack configuration
└── values/                  # Helm values files
    ├── argocd/
    │   └── values.yaml      # ArgoCD configuration
    ├── longhorn/
    │   └── values.yaml      # Longhorn storage configuration
    └── metallb/
        └── values.yaml      # MetalLB load balancer configuration
```

## Usage

The stack deployment playbook now supports both inline values (`set`) and external values files (`values_file`):

### Using Values Files (Recommended)
```yaml
applications:
  app-name:
    type: HELM
    chart:
      name: repo/chart-name
      version: x.y.z
    namespace: app-namespace
    values_file: deployment/stacks/values/app-name/values.yaml
```

### Using Inline Values (Legacy)
```yaml
applications:
  app-name:
    type: HELM
    chart:
      name: repo/chart-name
      version: x.y.z
    namespace: app-namespace
    set:
      key: value
      nested:
        key: value
```

## Application Configurations

### MetalLB (v0.15.2)
- **Purpose**: Load balancer for bare metal Kubernetes
- **Features**: Layer 2 and BGP support
- **Values**: `values/metallb/values.yaml`
- **Namespace**: `metallb-system`

### Longhorn (v1.8.2)
- **Purpose**: Cloud-native distributed storage
- **Features**: Persistent volumes, snapshots, backups
- **Values**: `values/longhorn/values.yaml`
- **Namespace**: `longhorn-system`
- **UI Access**: LoadBalancer service + Ingress at `longhorn.cicd.ryzen.io`

### ArgoCD (v8.1.3)
- **Purpose**: GitOps continuous delivery
- **Features**: Application management, Git sync
- **Values**: `values/argocd/values.yaml`
- **Namespace**: `argocd`
- **UI Access**: LoadBalancer service + Ingress at `argocd.cicd.ryzen.io`

## Deployment

Deploy the stack with:

```bash
cd /path/to/infra/ansible
export KUBECONFIG=/path/to/kubeconfig
ansible-playbook playbooks/stack_deployment.yml -e stack_file=../deployment/stacks/cicd-stack.yml
```

## Post-Deployment

1. **Configure MetalLB IP Pool**: Create IPAddressPool and L2Advertisement resources
2. **Access Services**: 
   - ArgoCD: http://argocd.cicd.ryzen.io
   - Longhorn: http://longhorn.cicd.ryzen.io
3. **Configure DNS**: Point hostnames to LoadBalancer IPs
4. **Optional**: Add cert-manager for TLS certificates

## Customization

Each values file can be customized independently:

- **Resource limits**: Adjust CPU/memory requests and limits
- **Ingress**: Configure hostnames, annotations, TLS
- **Security**: Configure RBAC, security contexts
- **Features**: Enable/disable specific features per application

## Monitoring

All applications support Prometheus monitoring via ServiceMonitor resources (disabled by default).
