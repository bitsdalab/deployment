# Infrastructure Setup

Components deployed via `infrastructure` ApplicationSet:

- **Longhorn 1.7.2**: Storage with RWX support via NFSv4 share-manager
- **Kong 2.39.3**: Ingress with LoadBalancer service  
- **cert-manager v1.16.2**: TLS certificates for `*.cicd.bitsb.dev`
- **Vault 0.29.1**: Secret management with auto-unseal
- **Velero 8.0.0**: Backup to MinIO servers (192.168.1.52/53)
- **Cilium LoadBalancer**: IP pool 192.168.1.100/28, L2 announcement

## Access URLs

- Longhorn: https://longhorn.cicd.bitsb.dev
- Vault: https://vault.cicd.bitsb.dev

## Key Files

```
argocd/applications/infrastructure/
├── cert-manager-ca-application.yaml
├── cilium-application.yaml
├── longhorn-application.yaml  
├── velero-application.yaml
└── manifests/
    ├── cert-manager/          # Self-signed CA setup
    ├── cilium/               # IP pool + L2 policy
    ├── longhorn/             # Prep job
    └── velero/               # MinIO credentials

argocd/values/
├── cert-manager/values.yaml  # Let's Encrypt config
├── kong/values.yaml          # LoadBalancer service
├── longhorn/values.yaml      # Storage settings  
├── vault/values.yaml         # HA + auto-unseal
└── velero/values.yaml        # External MinIO backup
```

## Storage Configuration

Default storage class `longhorn` supports both RWO and RWX.
Harbor uses RWX for rolling updates via NFSv4 share-manager.

## Network Configuration

LoadBalancer IP pool: 192.168.1.100/28
L2 announcement policy enables external access
Kong handles TLS termination for all ingress

## Backup Setup

Velero backs up to external MinIO servers:
- Primary: 192.168.1.52:9000
- Secondary: 192.168.1.53:9000
- Schedule: Every 4 hours
- Retention: 15 days

### 🗄️ Longhorn Storage System

**Your Setup**: Longhorn provides distributed storage with both RWO and RWX support via NFSv4 share-manager.

**Access**: https://longhorn.cicd.bitsb.dev (no auth by default)

**Your Configuration** (`argocd/values/longhorn/values.yaml`):
```yaml
defaultSettings:
  defaultDataPath: /var/lib/longhorn/
  defaultDataLocality: best-effort
  replicaSoftAntiAffinity: false
  storageOverProvisioningPercentage: 100
  storageMinimalAvailablePercentage: 25
```

**Storage Classes Available**:
```bash
# Check your storage classes
kubectl get storageclass
# NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
# longhorn (default)   driver.longhorn.io      Delete          Immediate

# Your Harbor uses RWX with this default class
kubectl describe storageclass longhorn
```

**Key Features in Your Setup**:
- **Default Storage Class**: `longhorn` supports both RWO and RWX
- **RWX Support**: Via NFSv4 share-manager for Harbor rolling updates
- **Data Path**: `/var/lib/longhorn/` on each node
- **Replication**: 3 replicas by default for high availability
- **ReadWriteMany (RWX)**: Volume can be mounted by multiple pods simultaneously

### 🌐 Kong Ingress Controller
**Purpose**: Manages external access to your cluster services

**What it does**:
- Routes external traffic to internal services
- Terminates TLS/SSL connections
- Provides LoadBalancer services for external access
- Integrates with cert-manager for automatic certificates

**Configuration**: `argocd/values/infrastructure/kong/values.yaml`

```bash
# Check ingress controller
kubectl get pods -n kong

# View LoadBalancer service
kubectl get svc -n kong kong-proxy

# Check ingress rules
kubectl get ingress -A
```

**Key Concepts**:
- **Ingress**: Kubernetes resource that defines external access rules
- **LoadBalancer**: Service type that provides external IP addresses
- **TLS Termination**: Decrypting HTTPS traffic at the ingress point

### 🔐 cert-manager (Certificate Management)
**Purpose**: Automatically provisions and renews TLS certificates

**What it does**:
- Integrates with Let's Encrypt for free SSL certificates
- Automatically renews certificates before expiration
- Creates wildcard certificates for `*.cicd.bitsb.dev`
- Stores certificates as Kubernetes secrets

**Configuration**: `argocd/values/infrastructure/cert-manager/values.yaml`

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# View certificates
kubectl get certificates -A

# Check certificate issuers
kubectl get clusterissuer
```

**Key Concepts**:
- **ClusterIssuer**: Defines how to get certificates (e.g., Let's Encrypt)
- **Certificate**: Kubernetes resource representing a TLS certificate
- **ACME**: Automated Certificate Management Environment (Let's Encrypt protocol)

### 🔑 Vault (Secret Management)
**Purpose**: Centralized, secure storage for sensitive data

**What it does**:
- Encrypts secrets at rest and in transit
- Provides fine-grained access control
- Integrates with Kubernetes authentication
- Automatically unseals using stored keys

**Access**: https://vault.cicd.bitsb.dev
**Configuration**: `argocd/values/infrastructure/vault/values.yaml`

```bash
# Check Vault status
kubectl get pods -n vault

# View Vault service
kubectl get svc -n vault

# Check Vault unseal status (from inside cluster)
kubectl exec -n vault vault-0 -- vault status
```

**Key Concepts**:
- **Seal/Unseal**: Vault starts "sealed" and must be unlocked with keys
- **Secret Engines**: Different ways to store secrets (key-value, database, etc.)
- **Policies**: Define what secrets users/apps can access

### 💾 Velero (Backup and Disaster Recovery)
**Purpose**: Backs up cluster resources and persistent volume data

**What it does**:
- Creates scheduled backups of Kubernetes resources
- Backs up persistent volume data
- Supports multiple backup storage locations
- Enables disaster recovery and cluster migration

**Configuration**: `argocd/values/infrastructure/velero/values.yaml`

```bash
# Check Velero
kubectl get pods -n velero

# View backup schedules
kubectl get schedules -n velero

# List backups
velero backup get
```

**Key Concepts**:
- **Backup Storage Location**: Where backups are stored (S3, MinIO, etc.)
- **Schedule**: Automated backup creation rules
- **Restore**: Process of recovering from backups

## 🚀 Infrastructure Deployment

### Automatic Deployment
When you run `./argocd/bootstrap.sh`, the infrastructure is deployed automatically:

1. **ArgoCD Projects**: Sets up RBAC and permissions
2. **Infrastructure ApplicationSet**: Deploys all infrastructure components
3. **Individual Applications**: Components like cert-manager, Kong, etc.

### Manual Operations
```bash
# Check infrastructure deployment status
kubectl get applications -n argocd | grep infrastructure

# View ApplicationSet
kubectl get applicationset infrastructure -n argocd

# Check sync status
argocd app list | grep infrastructure
```

## ⚙️ Configuration Management

### Helm Values Structure
Each component has its own values file:
```
argocd/values/infrastructure/
├── cert-manager/values.yaml      # Certificate management config
├── longhorn/values.yaml          # Storage configuration  
├── vault/values.yaml            # Secret management config
└── velero/values.yaml           # Backup configuration
```

### Example: Customizing Storage
Edit `argocd/values/infrastructure/longhorn/values.yaml`:
```yaml
# Increase default storage class replicas
defaultSettings:
  defaultReplicaCount: 3
  
# Enable automatic backup
recurringJobs:
  enable: true
  jobList: |
    [
      {
        "name": "backup",
        "cron": "0 2 * * *",
        "task": "backup",
        "groups": ["default"],
        "retain": 7
      }
    ]
```

## 🔧 Troubleshooting

### Common Infrastructure Issues

#### 1. Pods stuck in Pending state
**Symptoms**: Pods show `Pending` status
**Cause**: Usually storage or resource issues

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes

# Check storage classes
kubectl get storageclass
```

#### 2. Ingress not accessible
**Symptoms**: Can't reach services via URLs
**Cause**: LoadBalancer, DNS, or certificate issues

```bash
# Check LoadBalancer IP
kubectl get svc -n kong kong-proxy

# Check ingress resources
kubectl get ingress -A

# Check certificates
kubectl get certificates -A

# Test DNS resolution
nslookup vault.cicd.bitsb.dev
```

#### 3. Certificate issues
**Symptoms**: Browser shows certificate errors
**Cause**: cert-manager or Let's Encrypt issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check certificate challenges
kubectl get challenges -A
```

#### 4. Storage issues
**Symptoms**: PVCs stuck in Pending, pods can't mount volumes
**Cause**: Longhorn or node storage issues

```bash
# Check PVC status
kubectl get pvc -A

# Check Longhorn system
kubectl get pods -n longhorn-system

# Check node disk space
kubectl get nodes -o wide
```

#### 5. Vault sealed
**Symptoms**: Vault services return 503 errors
**Cause**: Vault is sealed and needs unsealing

```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status

# Check unseal secret exists
kubectl get secret vault-unseal-key -n vault

# Manual unseal (if needed)
kubectl exec -n vault vault-0 -- vault operator unseal <unseal-key>
```

### Debug Commands

```bash
# Infrastructure overview
kubectl get applications -n argocd | grep infrastructure
kubectl get pods -A | grep -E "(cert-manager|kong|longhorn|vault|velero)"

# Network connectivity
kubectl get svc -A --field-selector spec.type=LoadBalancer
kubectl get ingress -A

# Storage health
kubectl get storageclass
kubectl get pv
kubectl get pvc -A

# Certificate status
kubectl get certificates -A
kubectl get clusterissuer

# Resource usage
kubectl top nodes
kubectl top pods -A
```

## 🔐 Security Best Practices

### Network Security
- **TLS Everywhere**: All external traffic uses HTTPS
- **Internal Communication**: Services communicate over cluster DNS
- **Firewall Rules**: Only necessary ports exposed via LoadBalancer

### Secret Management
- **Vault Integration**: All sensitive data stored in Vault
- **Kubernetes Secrets**: Used only for service-to-service communication
- **No Hardcoded Secrets**: All secrets injected via environment or volumes

### Access Control
- **RBAC**: Role-based access control for all components
- **Service Accounts**: Minimal permissions for each service
- **Network Policies**: (Optional) Further restrict pod-to-pod communication

## 📈 Monitoring Infrastructure

### Health Checks
```bash
# Component health
kubectl get pods -A | grep -E "(cert-manager|kong|longhorn|vault|velero)"

# Certificate validity
kubectl get certificates -A -o custom-columns=NAME:.metadata.name,READY:.status.conditions[0].status,AGE:.metadata.creationTimestamp

# Storage health
kubectl get volumeattachments
kubectl get persistentvolumes
```

### Key Metrics to Watch
- **Pod Status**: All infrastructure pods should be Running
- **Certificate Expiry**: Certificates should auto-renew 30 days before expiry
- **Storage Usage**: Monitor disk space on nodes
- **Backup Success**: Verify Velero backups complete successfully

## 🚀 Next Steps

### Infrastructure Ready? 
Once your infrastructure is healthy:

1. **Deploy CI/CD**: Follow the [CI/CD Guide](CICD.md) to set up development tools
2. **Add Monitoring**: Check [Observability Guide](OBSERVABILITY.md) for monitoring stack
3. **Customize Configuration**: Modify values files for your specific needs

### Advanced Infrastructure Topics
- **Multi-cluster Setup**: Extend to multiple Kubernetes clusters
- **External Integrations**: Connect to external databases, storage, etc.
- **High Availability**: Configure components for zero-downtime
- **Performance Tuning**: Optimize for your specific workload patterns

---

**Need help?** 
- 📖 **Back to main guide**: [README.md](../README.md)
- 🔄 **Next: CI/CD setup**: [CI/CD Guide](CICD.md)
- 📊 **Monitoring**: [Observability Guide](OBSERVABILITY.md)
