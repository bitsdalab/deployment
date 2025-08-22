# ArgoCD GitOps Platform

Your Kubernetes platform deployment for `cicd.bitsb.dev` using ArgoCD ApplicationSets.

## Platform Components

**Infrastructure**: Longhorn storage, Kong ingress, cert-manager TLS, Vault secrets, Velero backup, Cilium LoadBalancer
**CI/CD**: Authentik SSO, Harbor registry, Jenkins automation  
**Observability**: Planned (Prometheus, Grafana, Loki)

## Quick Access

- ArgoCD: https://argocd.cicd.bitsb.dev
- Longhorn: https://longhorn.cicd.bitsb.dev  
- Vault: https://vault.cicd.bitsb.dev
- Authentik: https://authentik.cicd.bitsb.dev
- Harbor: https://harbor.cicd.bitsb.dev
- Jenkins: https://jenkins.cicd.bitsb.dev

## Bootstrap

```bash
./argocd/bootstrap.sh
```

## Documentation

- **[Infrastructure Setup](docs/INFRASTRUCTURE.md)** - Storage, networking, security
- **[CI/CD Setup](docs/CICD.md)** - Development workflow tools  
- **[Observability Plan](docs/OBSERVABILITY.md)** - Future monitoring stack

## 🎯 Quick Start

### Prerequisites
1. **Kubernetes cluster** with kubectl access
2. **ArgoCD installed** via [bitsdalab/infra](https://github.com/bitsdalab/infra) repository
3. **Environment variables** set for automation

### Environment Setup (macOS)
Add to your `~/.zshrc`:
```zsh
# Vault Unseal Key (for automated secret management)
export VAULT_UNSEAL_KEY="<your-unseal-key>"

# GitHub Repository Access (for GitOps)
export GITHUB_USERNAME="<your-github-username>"
export GITHUB_TOKEN="<your-github-token>"
```

Reload: `source ~/.zshrc`

### 🚀 Deploy the Platform
```bash
# Clone this repository
git clone https://github.com/bitsdalab/deployment.git
cd deployment

# Run the automated bootstrap
chmod +x argocd/bootstrap.sh
./argocd/bootstrap.sh
```

The bootstrap script will:
1. 🔐 **Configure secrets** (Vault unseal, GitHub access)
2. 🏗️ **Deploy infrastructure** (storage, networking, security)
3. 🔄 **Setup CI/CD** (identity, registry, automation)
4. 📊 **Prepare observability** (monitoring stack - coming soon)

### 🌐 Access Your Platform
After deployment, add to `/etc/hosts`:
```
<CLUSTER_IP>    argocd.cicd.bitsb.dev
<CLUSTER_IP>    longhorn.cicd.bitsb.dev  
<CLUSTER_IP>    vault.cicd.bitsb.dev
<CLUSTER_IP>    authentik.cicd.bitsb.dev
<CLUSTER_IP>    harbor.cicd.bitsb.dev
<CLUSTER_IP>    jenkins.cicd.bitsb.dev
```

Find your cluster IP:
```bash
kubectl get svc -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## 🧭 Navigation Guide

**New to DevOps/GitOps?** Start here:
1. 📖 Read [Infrastructure Guide](docs/INFRASTRUCTURE.md) to understand the foundation
2. 🔄 Follow [CI/CD Guide](docs/CICD.md) to set up your development workflow  
3. 📊 Check [Observability Guide](docs/OBSERVABILITY.md) for monitoring (coming soon)

**Experienced with Kubernetes?** Jump to:
- 🏗️ [Infrastructure Guide](docs/INFRASTRUCTURE.md) for storage, networking, and security details
- 🔄 [CI/CD Guide](docs/CICD.md) for development pipeline configuration
- 📊 [Observability Guide](docs/OBSERVABILITY.md) for monitoring stack setup

**Need to troubleshoot?** Visit:
- 🔧 [Infrastructure Troubleshooting](docs/INFRASTRUCTURE.md#troubleshooting)
- 🔧 [CI/CD Troubleshooting](docs/CICD.md#troubleshooting)  
- 🔧 [Observability Troubleshooting](docs/OBSERVABILITY.md#troubleshooting)

## 📁 Repository Structure

```
deployment/
├── README.md                          # 👈 You are here - Main entry point
├── docs/                              # 📚 Detailed guides
│   ├── INFRASTRUCTURE.md               # 🏗️ Storage, networking, security
│   ├── CICD.md                        # 🔄 Development workflow
│   └── OBSERVABILITY.md               # 📊 Monitoring and logging
├── argocd/                            # 🎛️ GitOps configurations
│   ├── bootstrap.sh                   # 🚀 Main deployment script
│   ├── applications/                  # 📦 Individual app configs
│   ├── appsets/                       # 🔄 Application sets (patterns)
│   ├── bootstrap/                     # 🎯 Root applications
│   ├── projects/                      # 🔐 RBAC and permissions
│   └── values/                        # ⚙️ Helm configuration
└── scripts/                           # 🛠️ Utility scripts
```

## 🤝 Understanding GitOps Workflow

### How Changes Work
1. **Make Changes**: Edit files in this Git repository
2. **Review**: Create pull request for team review
3. **Merge**: Changes are merged to main branch
4. **Auto-Deploy**: ArgoCD detects changes and updates cluster
5. **Monitor**: Check ArgoCD UI to see deployment status

### ArgoCD Applications
- **Applications**: Individual components (like Harbor, Jenkins)
- **ApplicationSets**: Templates that create multiple similar applications
- **Projects**: Group applications and define permissions
- **Sync Policies**: How and when to deploy changes

## 🆘 Quick Troubleshooting

### Common Issues
```bash
# Check if ArgoCD is working
kubectl get applications -n argocd

# Check if pods are running
kubectl get pods -A

# Check ingress and LoadBalancer
kubectl get svc -A --field-selector spec.type=LoadBalancer
kubectl get ingress -A

# Check certificates
kubectl get certificates -A
```

### Get Help
- 🏗️ **Infrastructure issues**: See [Infrastructure Troubleshooting](docs/INFRASTRUCTURE.md#troubleshooting)
- 🔄 **CI/CD issues**: See [CI/CD Troubleshooting](docs/CICD.md#troubleshooting)
- 📊 **Monitoring issues**: See [Observability Troubleshooting](docs/OBSERVABILITY.md#troubleshooting)

## 🎓 Learning Path

**For Beginners:**
1. **Understand Kubernetes basics** (pods, services, deployments)
2. **Learn GitOps concepts** (declarative config, reconciliation loops)
3. **Deploy this platform** and explore each component
4. **Make small changes** to see GitOps in action

**For Advanced Users:**
1. **Customize the platform** for your specific needs
2. **Add new applications** using ApplicationSets
3. **Integrate with existing systems** (LDAP, monitoring, etc.)
4. **Contribute improvements** back to the repository

## 🔐 Security Considerations

- **TLS Everywhere**: All services use HTTPS with automatic certificates
- **Secret Management**: Vault provides centralized secret storage
- **RBAC**: ArgoCD projects control who can deploy what
- **Image Security**: Harbor scans containers for vulnerabilities
- **Backup**: Velero ensures you can recover from disasters

## 🌟 What Makes This Special

- **Beginner Friendly**: Detailed guides for newcomers to DevOps
- **Production Ready**: Used in real environments, not just demos
- **GitOps Native**: Everything is managed through Git workflows
- **Modular Design**: Use only what you need, add more later
- **Open Source**: No vendor lock-in, fully transparent

---

**Ready to start?** Choose your path:
- 🏗️ **[Infrastructure Guide](docs/INFRASTRUCTURE.md)** - Understand the foundation
- 🔄 **[CI/CD Guide](docs/CICD.md)** - Set up development workflow
- 📊 **[Observability Guide](docs/OBSERVABILITY.md)** - Monitor everything
---

**Ready to start?** Choose your path:
- 🏗️ **[Infrastructure Guide](docs/INFRASTRUCTURE.md)** - Understand the foundation
- 🔄 **[CI/CD Guide](docs/CICD.md)** - Set up development workflow
- 📊 **[Observability Guide](docs/OBSERVABILITY.md)** - Monitor everything
