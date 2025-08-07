# ArgoCD GitOps Platform Bootstrap

This repository provides a complete GitOps-based Kubernetes platform deployment using ArgoCD, supporting both infrastructure and CICD components.

## Environment Variable Setup (macOS)

To automate Vault unseal and bootstrap, set your unseal key(s) and GitHub credentials as environment variables in your shell profile (e.g., `~/.zshrc` for macOS):

### Required Environment Variables
Add to your `~/.zshrc`:
```zsh
# Vault Unseal Key (Standalone Mode)
export VAULT_UNSEAL_KEY="<your-unseal-key>"

# GitHub Repository Access
export GITHUB_USERNAME="<your-github-username>"
export GITHUB_TOKEN="<your-github-token>"
```

Reload your shell:
```zsh
source ~/.zshrc
```

### HA Mode (Multiple Vault Keys)
For Vault HA deployments, you can set multiple keys (though the current bootstrap script uses single key mode):
```zsh
export VAULT_UNSEAL_KEY="<your-single-unseal-key>"
```

**Note**: The current `bootstrap.sh` script is configured for single-key mode only. For HA setups with multiple keys, additional script modifications would be required.

**Security Note:**
- Never commit your unseal keys, tokens, or credentials to source control
- Restrict access to your shell profile and secrets
- Use GitHub tokens with minimal required permissions
# GitOps Platform Architecture

## Overview
This GitOps platform provides automated deployment and management of Kubernetes infrastructure and CICD components using ArgoCD ApplicationSets and Applications.

**Architecture**: ArgoCD is deployed and managed via the [bitsdalab/infra](https://github.com/bitsdalab/infra) repository using Ansible playbooks. This repository contains the GitOps configurations and bootstrap scripts for the platform components.

## Key Features ✨
- **GitOps Workflow**: Declarative infrastructure and application management
- **ArgoCD ApplicationSets**: Automated application deployment patterns
- **Vault Integration**: Automated unseal and secret management
- **TLS Automation**: Automatic certificate management with cert-manager
- **CICD Platform**: Complete CI/CD pipeline with Authentik, Harbor, and Jenkins
- **Infrastructure Components**: cert-manager, Kong ingress, Longhorn storage, External Secrets Operator
- **Bootstrap Automation**: Single-command platform deployment

## Platform Components

### Infrastructure Layer
- **cert-manager**: TLS certificate management with Let's Encrypt
- **Kong**: Ingress controller with TLS termination
- **Longhorn**: Distributed block storage
- **Velero**: Backup and disaster recovery
- **External Secrets Operator**: External secret management integration
- **Vault**: Secret management and encryption

### CICD Layer
- **ArgoCD**: GitOps continuous deployment (managed via [infra repository](https://github.com/bitsdalab/infra))
- **Authentik**: Identity provider and SSO
- **Harbor**: Container registry with security scanning
- **Jenkins**: CI/CD automation server

## Repository Structure
```
deployment/
├── README.md                     # This documentation
├── argocd/
│   ├── bootstrap.sh              # Main bootstrap script
│   ├── applications/             # Individual applications
│   │   └── infrastructure/       # Infrastructure apps
│   ├── appsets/                  # ApplicationSets
│   │   ├── infrastructure/       # Infrastructure AppSet
│   │   └── cicd/                 # CICD AppSet
│   ├── bootstrap/                # Bootstrap root applications
│   ├── projects/                 # ArgoCD projects (RBAC)
│   └── values/                   # Helm values files
│       ├── authentik/
│       ├── cert-manager/
│       ├── external-secrets-operator/
│       ├── harbor/
│       ├── jenkins/
│       ├── kong/
│       ├── longhorn/
│       ├── vault/
│       └── velero/
```
## Bootstrap Deployment

### Prerequisites
1. **Kubernetes Cluster**: Running cluster with kubectl access
2. **ArgoCD**: Deployed via the [infra repository](https://github.com/bitsdalab/infra) playbook
3. **Environment Variables**: Set VAULT_UNSEAL_KEY, GITHUB_USERNAME, GITHUB_TOKEN

**Note**: ArgoCD itself is managed separately from the [bitsdalab/infra](https://github.com/bitsdalab/infra) repository using Ansible playbooks. This repository assumes ArgoCD is already installed and accessible.

### Quick Start
```bash
# 1. First, deploy ArgoCD using the infra repository
git clone https://github.com/bitsdalab/infra.git
# Follow the infra repository instructions to deploy ArgoCD

# 2. Then, bootstrap the GitOps platform
git clone https://github.com/bitsdalab/deployment.git
cd deployment

# Run the bootstrap script
chmod +x argocd/bootstrap.sh
./argocd/bootstrap.sh
```

### Bootstrap Process
The `bootstrap.sh` script automates the complete platform deployment:

#### Step 0: Vault Unseal Key Secret
- Creates Kubernetes secret for automated Vault unseal
- Prompts for unseal key if not set in environment
- Configures secret in `vault` namespace

#### Step 1: Repository Access Setup
- Configures GitHub repository credentials
- Creates ArgoCD repository secret
- Enables GitOps access to deployment configurations

#### Step 2: ArgoCD Projects (RBAC)
- Applies ArgoCD projects for namespace isolation
- Configures RBAC permissions
- Sets up `infrastructure` and `cicd` projects

#### Step 3: Infrastructure Bootstrap
- Deploys infrastructure Applications root
- Deploys infrastructure ApplicationSets root
- Installs: cert-manager, Kong, Longhorn, Velero, External Secrets Operator, Vault

#### Step 4: CICD Platform Bootstrap
- Deploys CICD ApplicationSets root
- Installs: Authentik, Harbor, Jenkins
- Configures identity, registry, and CI/CD services

#### Step 5: Access Information
- Displays service URLs and credentials
- Provides /etc/hosts configuration
- Shows monitoring commands

### Network Configuration
Add these entries to your `/etc/hosts` file:
```
# Replace <CLUSTER_IP> with your actual cluster IP
<CLUSTER_IP>    authentik.cicd.bitsb.dev
<CLUSTER_IP>    harbor.cicd.bitsb.dev
<CLUSTER_IP>    jenkins.cicd.bitsb.dev
```

Find your cluster IP:
```bash
kubectl get svc -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Default Credentials
- **Harbor**: https://harbor.cicd.bitsb.dev (admin / Harbor12345)
- **Jenkins**: https://jenkins.cicd.bitsb.dev (admin / admin123)
- **Authentik**: https://authentik.cicd.bitsb.dev (setup required on first access)

## Vault Unseal Automation

### Automated Unseal Pattern
The deployment supports automated Vault unseal using:
- **Kubernetes Secret**: Stores unseal key(s) securely
- **Sidecar Container**: Monitors and unseals Vault automatically
- **Bootstrap Integration**: Creates secrets during deployment

### Standalone Mode (Single Key)
```bash
# Initialize Vault with single key
vault operator init -key-shares=1 -key-threshold=1

# Set environment variable
export VAULT_UNSEAL_KEY="<your-unseal-key>"
```

### HA Mode (Multiple Keys)
```bash
# Initialize Vault with single key (current setup)
vault operator init -key-shares=1 -key-threshold=1

# Set environment variable (same as standalone mode)
export VAULT_UNSEAL_KEY="<your-unseal-key>"
```

**Note**: The current bootstrap script uses single-key mode for both standalone and HA scenarios. True HA with multiple keys would require additional configuration.

### Security Considerations
- Unseal keys are sensitive - use RBAC to restrict secret access
- Consider Vault's [auto-unseal](https://www.vaultproject.io/docs/concepts/seal) for production
- Regularly rotate and backup unseal keys securely

## GitOps Management

### ArgoCD Applications
Monitor and manage applications through ArgoCD:
```bash
# View all applications
kubectl get applications -n argocd

# Monitor deployment progress
kubectl get applications -n argocd -w

# Check ApplicationSets
kubectl get applicationsets -n argocd

# View sync status
argocd app list
```

### Application Structure
- **ArgoCD**: Deployed separately via [infra repository](https://github.com/bitsdalab/infra)
- **Infrastructure Apps**: Core platform components (cert-manager, Kong, Longhorn, Velero, External Secrets Operator, Vault)
- **CICD Apps**: Developer platform components (Authentik, Harbor, Jenkins)
- **ApplicationSets**: Automated deployment patterns for multiple applications

### Helm Values Management
Values files are organized by component:
```
argocd/values/
├── authentik/values.yaml                    # Identity provider configuration
├── cert-manager/values.yaml                 # Certificate management
├── external-secrets-operator/values.yaml    # External secrets integration
├── harbor/values.yaml                       # Container registry
├── jenkins/values.yaml                      # CI/CD server
├── kong/values.yaml                        # Ingress controller
├── longhorn/values.yaml                    # Storage system
├── vault/values.yaml                       # Secret management
└── velero/values.yaml                      # Backup system
```

## CICD Platform Services

### Authentik (Identity Provider)
- **URL**: https://authentik.cicd.bitsb.dev
- **Purpose**: SSO and identity management
- **Initial Setup**: Navigate to `/if/flow/initial-setup/` on first access
- **Features**: SAML, OAuth2, LDAP integration

### Harbor (Container Registry)
- **URL**: https://harbor.cicd.bitsb.dev  
- **Credentials**: admin / Harbor12345
- **Purpose**: Container image storage and security scanning
- **Features**: Vulnerability scanning, image signing, replication

### Jenkins (CI/CD Server)
- **URL**: https://jenkins.cicd.bitsb.dev
- **Credentials**: admin / admin123
- **Purpose**: Build automation and CI/CD pipelines
- **Features**: Pipeline as code, plugin ecosystem, distributed builds

## Troubleshooting

### Common Issues
1. **ArgoCD sync failures**: Check repository access and credentials
2. **Certificate issues**: Verify cert-manager and ClusterIssuer configuration
3. **Ingress not accessible**: Check Kong controller and LoadBalancer service
4. **Storage issues**: Validate Longhorn installation and node dependencies
5. **Vault sealed**: Ensure unseal key secret is properly configured

### Debug Commands
```bash
# Check all pods status
kubectl get pods -A

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress resources
kubectl get ingress -A

# Check certificates
kubectl get certificates -A

# Check storage classes
kubectl get storageclass

# View component logs
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd
kubectl logs -l app.kubernetes.io/name=kong -n kong
kubectl logs -l app=cert-manager -n cert-manager
```

### Service Health Checks
```bash
# Kong ingress controller
curl -k https://kong.kong.svc.cluster.local:8443/status

# ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Certificate validation
openssl s_client -connect authentik.cicd.bitsb.dev:443 -servername authentik.cicd.bitsb.dev
```

## Security Considerations

### TLS/SSL
- All ingress traffic is automatically redirected to HTTPS
- Wildcard certificates for `*.cicd.bitsb.dev`
- Let's Encrypt production certificates with automatic renewal
- Kong ingress controller handles TLS termination

### Access Control
- ArgoCD projects provide namespace isolation and RBAC
- Service accounts with minimal required permissions
- Authentik provides centralized identity management
- Harbor registry access controls and vulnerability scanning

### Secret Management
- Vault provides centralized secret storage and encryption
- Kubernetes secrets for service-to-service communication
- GitHub repository access via secure tokens
- Automated Vault unseal with secure key storage

### Network Security
- Kong ingress provides secure external access
- Internal service communication via cluster DNS
- TLS encryption for all inter-service communication
- Longhorn storage encryption at rest

## Backup Strategy

### Velero Backup System
The platform includes automated backup capabilities with external MinIO storage support for multi-node setups:

#### Basic Velero Operations
```bash
# View backup schedules
kubectl get schedules -n velero

# Create manual backup
velero backup create manual-backup --include-namespaces=argocd,vault,authentik,harbor,jenkins

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup <backup-name>
```

#### External MinIO Configuration
For production deployments, configure Velero with external MinIO servers for redundant backup storage:

##### MinIO Credentials Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: velero-minio-creds
  namespace: velero
type: Opaque
stringData:
  cloud: |
    [default]
    aws_access_key_id = <MINIO_ACCESS_KEY>
    aws_secret_access_key = <MINIO_SECRET_KEY>
```

##### Backup Storage Locations (Multi-Node)
Configure multiple backup storage locations for redundancy:

**Primary Node (192.168.1.52)**:
```yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: minio-node-1
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero
  config:
    region: us-east-1
    s3Url: http://192.168.1.52:9000
    insecureSkipTLSVerify: "true"
  credential:
    name: velero-minio-creds
    key: cloud
```

**Secondary Node (192.168.1.53)**:
```yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: minio-node-2
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero
  config:
    region: us-east-1
    s3Url: http://192.168.1.53:9000
    insecureSkipTLSVerify: "true"
  credential:
    name: velero-minio-creds
    key: cloud
```

##### Automated Backup Schedules
Create scheduled backups for both storage locations (every 4 hours):

**Primary Schedule**:
```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: backup-every-4h-node1
  namespace: velero
spec:
  schedule: "0 */4 * * *"
  template:
    includedNamespaces:
      - '*'
    ttl: 360h
    storageLocation: minio-node-1
    snapshotVolumes: false
```

**Secondary Schedule**:
```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: backup-every-4h-node2
  namespace: velero
spec:
  schedule: "0 */4 * * *"
  template:
    includedNamespaces:
      - '*'
    ttl: 360h
    storageLocation: minio-node-2
    snapshotVolumes: false
```

##### Manual Testing
Create immediate test backups for each storage location:

**Test Backup to Primary Node**:
```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: test-backup-node1
  namespace: velero
spec:
  includedNamespaces:
    - '*'
  storageLocation: minio-node-1
  ttl: 240h
  snapshotVolumes: false
```

**Test Backup to Secondary Node**:
```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: test-backup-node2
  namespace: velero
spec:
  includedNamespaces:
    - '*'
  storageLocation: minio-node-2
  ttl: 240h
  snapshotVolumes: false
```

Apply test backups:
```bash
kubectl apply -f <backup-yaml-file>
kubectl -n velero get backup
```

#### Backup Configuration Notes
- **Volume Snapshots**: Set `snapshotVolumes: false` to disable volume snapshots when using Longhorn for PV management
- **TTL Settings**: Backups are retained for 360 hours (15 days) for scheduled backups, 240 hours (10 days) for test backups
- **Security**: MinIO connections use `insecureSkipTLSVerify: "true"` for internal cluster communication
- **Bucket Names**: Both nodes use the same bucket name `velero` for consistency

### Critical Data Protection
- **ArgoCD**: Configuration and application definitions
- **Vault**: Encrypted secrets and policies
- **Harbor**: Container images and metadata
- **Jenkins**: Job configurations and build history
- **Authentik**: User accounts and SSO configuration

## Monitoring and Observability

### Built-in Health Checks
- ArgoCD application sync status and health
- Certificate validity and renewal status
- Storage class and persistent volume status
- Service endpoint reachability and response times

### Future Integration Points
Ready for observability stack integration:
- **Prometheus**: Metrics collection from all components
- **Grafana**: Visualization and alerting dashboards
- **Loki**: Centralized log aggregation
- **Tempo**: Distributed tracing capabilities

**Note**: Observability stack is not currently deployed but the platform is ready for integration.

## Platform Customization

### Adding New Applications
1. **Create Application Definition**: Add to appropriate ApplicationSet in `argocd/appsets/`
2. **Add Helm Values**: Create values file in `argocd/values/<app-name>/`
3. **Configure Project Access**: Update ArgoCD project permissions if needed
4. **Update Bootstrap**: Add any required secrets or dependencies

### Custom Values Configuration
Each component uses a dedicated values file for customization:
```yaml
# Example: Custom Kong configuration
# argocd/values/kong/values.yaml
image:
  tag: "3.5"
env:
  router_flavor: traditional
proxy:
  type: LoadBalancer
```

### ApplicationSet Patterns
The platform uses ApplicationSets for automated application management:
```yaml
# Infrastructure ApplicationSet
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: infrastructure
spec:
  generators:
  - list:
      elements:
      - name: cert-manager
        namespace: cert-manager
        repoURL: https://charts.jetstack.io
        chart: cert-manager
        targetRevision: v1.16.2
  template:
    # Application template with Helm source
```

### Environment-Specific Configuration
Customize deployments for different environments:
- **Development**: Reduced resource limits, debug logging
- **Staging**: Production-like settings with test data
- **Production**: Full resource allocation, security hardening

## Migration and Upgrades

### Component Upgrades
Upgrade individual components through GitOps:
1. Update chart version in ApplicationSet
2. Update values files if needed
3. Commit changes to trigger ArgoCD sync
4. Monitor deployment status

### Platform Migration
Steps for migrating to new cluster:
1. **Backup Data**: Use Velero to backup all namespaces
2. **Export Secrets**: Backup Vault unseal keys and GitHub tokens
3. **Deploy Platform**: Run bootstrap script on new cluster
4. **Restore Data**: Use Velero restore functionality
5. **Validate Services**: Verify all components are functional

### Version Management
- **Semantic Versioning**: All Helm charts use semantic versions
- **Automated Updates**: Renovate bot can manage dependency updates
- **Rollback Support**: ArgoCD provides easy rollback capabilities
- **Change Tracking**: Git history provides full audit trail

## Production Readiness

### High Availability Considerations
- **Multi-node Deployment**: Distribute components across multiple nodes
- **Resource Limits**: Set appropriate CPU and memory limits
- **Health Checks**: Configure readiness and liveness probes
- **Backup Strategy**: Regular automated backups with Velero

### Performance Optimization
- **Resource Allocation**: Size components based on expected load
- **Storage Performance**: Use high-performance storage classes
- **Network Optimization**: Configure ingress for optimal routing
- **Monitoring**: Implement comprehensive observability

### Disaster Recovery
- **Backup Automation**: Scheduled backups to external storage
- **Recovery Procedures**: Documented restore processes
- **Data Replication**: Cross-region backup storage
- **RTO/RPO Targets**: Defined recovery time and point objectives

## Conclusion

This GitOps platform provides a production-ready, automated approach to Kubernetes infrastructure and CICD management that:

- **Simplifies Deployment**: Single-command bootstrap for complete platform (after ArgoCD deployment via infra repo)
- **Ensures Consistency**: GitOps workflow maintains declarative state
- **Provides Security**: Comprehensive security controls and secret management
- **Enables Scalability**: Modular architecture supports growth and customization
- **Facilitates Operations**: Built-in monitoring, backup, and troubleshooting capabilities

**Deployment Flow**:
1. **Infrastructure Setup**: Use [bitsdalab/infra](https://github.com/bitsdalab/infra) to deploy ArgoCD and cluster foundations
2. **Platform Bootstrap**: Use this repository to deploy the complete GitOps platform components

The platform serves as a solid foundation for any organization looking to implement modern DevOps practices with Kubernetes, providing both infrastructure services and a complete CICD pipeline that can be customized and extended to meet specific requirements.
