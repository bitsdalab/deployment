# Generic Kubernetes Stack Deployment with Ansible

## Overview
This deployment system provides a **fully automated, generic, and idempotent** Ansible playbook for deploying Kubernetes application stacks using Helm charts, with comprehensive support for pre- and post-deployment automation.

## Key Features ✨
- **Generic Playbook**: All stack-specific logic is defined in stack YAML files
- **Pre/Post Deployment Hooks**: Support for resources, files, and scripts
- **Node-Level Dependency Management**: Automated installation of required system packages
- **TLS Automation**: Automatic certificate management with cert-manager
- **LoadBalancer Automation**: MetalLB configuration with IP pools
- **Service Validation**: Post-deployment health checks and monitoring
- **Idempotent**: Safe to run multiple times without side effects

## Directory Structure
```
deployment/
├── stack_deployment.yml          # Generic Ansible playbook
└── stacks/
    ├── cicd-stack.yml            # Stack definition (example)
    ├── values/                   # Helm values files
    │   ├── metallb/values.yaml
    │   ├── cert-manager/values.yaml
    │   ├── kong/values.yaml
    │   ├── longhorn/values.yaml
    │   └── argocd/values.yaml
    ├── pre-deploy/               # Pre-deployment automation
    │   ├── install-longhorn-deps.sh
    │   └── validate-longhorn-deps.sh
    └── post-deploy/              # Post-deployment automation
        ├── wait-for-services.sh
        └── example-ingress.yaml
```

## Usage

### Deploy a Stack
```bash
# Deploy the CI/CD stack
ansible-playbook stack_deployment.yml -e stack_file=deployment/stacks/cicd-stack.yml

# Deploy with custom values
ansible-playbook stack_deployment.yml \
  -e stack_file=deployment/stacks/cicd-stack.yml \
  -e metallb_values=custom-metallb-values.yaml
```

### Stack Definition Format
The stack YAML file defines everything about your deployment:

```yaml
deployment:
  name: "my-stack"
  namespace: "default"
  
  # Helm repositories
  repositories:
    - name: argo
      url: https://argoproj.github.io/argo-helm
  
  # Pre-deployment automation (runs BEFORE Helm charts)
  pre_deploy_resources: []     # Kubernetes manifests
  pre_deploy_files: []         # File creation/templating
  pre_deploy_scripts: []       # Shell scripts for setup
  
  # Post-deployment automation (runs AFTER Helm charts)
  post_deploy_resources: []    # Kubernetes manifests
  post_deploy_files: []        # File creation/templating
  post_deploy_scripts: []      # Shell scripts for validation
  
# Applications to deploy
applications:
  my-app:
    type: HELM
    chart:
      name: repository/chart-name
      version: "1.0.0"
    namespace: app-namespace
    values_file: deployment/stacks/values/my-app/values.yaml
```

## Automation Features

### Pre-Deployment Hooks
**Purpose**: Prepare the cluster environment before application deployment

**Examples**:
- Install system dependencies (like open-iscsi for Longhorn)
- Create namespaces with specific security policies
- Set up RBAC and service accounts
- Install CRDs or operators

**Implementation**:
```yaml
pre_deploy_scripts:
  - "bash pre-deploy/install-longhorn-deps.sh"
  - "bash pre-deploy/validate-longhorn-deps.sh"

pre_deploy_resources:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: monitoring
      labels:
        security: restricted

pre_deploy_files:
  - name: "config.yaml"
    path: "/tmp/app-config.yaml"
    content: |
      # Configuration content here
```

### Post-Deployment Hooks
**Purpose**: Configure services and validate deployment after Helm charts are installed

**Examples**:
- Configure MetalLB IP address pools
- Set up cert-manager ClusterIssuers
- Create SSL certificates
- Configure ingress resources
- Run health checks and validation

**Implementation**:
```yaml
post_deploy_scripts:
  - "bash post-deploy/wait-for-services.sh"

post_deploy_resources:
  - apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default-pool
      namespace: metallb-system
    spec:
      addresses:
        - "192.168.1.240-192.168.1.250"
```

## Example Stack: CI/CD Platform

The included `cicd-stack.yml` demonstrates a complete CI/CD platform deployment:

### Components
1. **MetalLB**: LoadBalancer implementation
2. **cert-manager**: TLS certificate management
3. **Kong**: Ingress controller with TLS termination
4. **Longhorn**: Distributed block storage
5. **ArgoCD**: GitOps continuous deployment

### Automation Flow
```
1. Pre-Deploy: Install Longhorn dependencies (open-iscsi)
2. Pre-Deploy: Validate node readiness
3. Deploy: Install all Helm charts in correct order
4. Post-Deploy: Configure MetalLB IP pools
5. Post-Deploy: Set up cert-manager ClusterIssuers
6. Post-Deploy: Create wildcard SSL certificates
7. Post-Deploy: Validate service health and certificates
```

### Network Configuration
- **LoadBalancer IP Range**: `192.168.1.240-192.168.1.250`
- **Domain**: `bitsb.dev` and `*.cicd.bitsb.dev`
- **TLS**: Automated Let's Encrypt certificates
- **Ingress**: Kong with automatic HTTPS redirect

## Node Dependency Management

### Problem Solved
Longhorn storage requires `open-iscsi` to be installed on all Kubernetes nodes, but this is a host-level dependency that can't be managed by Kubernetes directly.

### Solution
The pre-deployment script `install-longhorn-deps.sh`:
1. Creates a privileged DaemonSet that runs on all nodes
2. Uses `nsenter` to install packages in the host namespace
3. Installs and configures `open-iscsi` service
4. Validates installation before proceeding
5. Cleans up the installer DaemonSet

### Validation
The `validate-longhorn-deps.sh` script ensures all nodes are ready:
- Checks for `iscsiadm` command availability
- Verifies `iscsid` service is running
- Provides clear success/failure reporting

## Service Validation

### Post-Deploy Health Checks
The `wait-for-services.sh` script provides comprehensive validation:

```bash
# Wait for LoadBalancer IPs
kubectl wait --for=condition=ready service/kong-proxy -n ingress --timeout=300s

# Check certificate status
kubectl get certificates -A

# Validate ingress endpoints
curl -f https://argocd.cicd.bitsb.dev/health

# Storage validation
kubectl get storageclass longhorn
```

## Customization

### Adding New Applications
1. Add Helm repository to `repositories` section
2. Define application in `applications` section
3. Create values file in `deployment/stacks/values/app-name/`
4. Add any pre/post deployment hooks as needed

### Custom Scripts and Resources
1. Create script files in `pre-deploy/` or `post-deploy/`
2. Reference them in stack YAML `pre_deploy_scripts` or `post_deploy_scripts`
3. Add Kubernetes resources to `pre_deploy_resources` or `post_deploy_resources`

## Troubleshooting

### Common Issues
1. **Longhorn fails with iscsiadm error**: Run pre-deploy dependency installer
2. **Certificates not issuing**: Check cert-manager ClusterIssuer configuration
3. **LoadBalancer pending**: Verify MetalLB IP pool configuration
4. **Ingress not working**: Check Kong controller and certificates

### Debug Commands
```bash
# Check pod status
kubectl get pods -A

# Check service endpoints
kubectl get svc -A

# Check certificate status
kubectl get certificates -A

# Check ingress configuration
kubectl get ingress -A

# View logs
kubectl logs -l app=longhorn-manager -n longhorn-system
kubectl logs -l app=cert-manager -n cert-manager
```

## Security Considerations

### TLS/SSL
- All ingress traffic is automatically redirected to HTTPS
- Wildcard certificates for `*.bitsb.dev` and `*.cicd.bitsb.dev`
- Let's Encrypt production certificates with automatic renewal

### Network Policies
- Namespaces are configured with security labels
- Pod security standards enforcement
- Ingress-only external access (no NodePort/host networking)

### RBAC
- Service accounts with minimal required permissions
- Namespace isolation for different components
- ArgoCD with admin access only to designated namespaces

## Monitoring and Observability

### Built-in Health Checks
- LoadBalancer service availability
- Certificate validity and renewal status
- Storage class and volume provisioning
- Ingress endpoint reachability

### Integration Points
- Ready for Prometheus/Grafana stack
- ArgoCD provides GitOps observability
- Longhorn dashboard for storage monitoring
- Kong provides ingress metrics

## Conclusion

This deployment system provides a production-ready, automated approach to Kubernetes stack deployment that:
- **Eliminates manual steps** through comprehensive automation
- **Scales to any stack size** with the generic playbook approach
- **Handles complex dependencies** including node-level requirements
- **Provides validation and monitoring** for reliable operations
- **Follows security best practices** for production environments

The system is designed to be the foundation for any Kubernetes-based platform, from simple applications to complex multi-service architectures like CI/CD pipelines, observability stacks, or data platforms.
