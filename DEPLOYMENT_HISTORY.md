# Deployment History and Version Tracking

## Component Versions (Current)
Last Updated: July 19, 2025

| Component | Version | Chart Version | Notes |
|-----------|---------|---------------|-------|
| MetalLB | 0.15.2 | 0.15.2 | LoadBalancer provider |
| Kong Gateway | 3.8 | 2.40.0 | API Gateway (DB-less mode) |
| cert-manager | 1.16.2 | v1.16.2 | TLS certificate management |
| Longhorn | 1.8.2 | 1.8.2 | Distributed storage |
| ArgoCD | 2.13.x | 8.1.3 | GitOps platform |

## Deployment History

### 2025-07-19 - Initial Deployment
- **Stack**: Complete CI/CD infrastructure
- **Domain Strategy**: Wildcard certificates for *.bitsb.dev and *.cicd.bitsb.dev
- **Ingress**: Kong Gateway (replaced NGINX)
- **Storage**: Longhorn distributed storage
- **LoadBalancer**: MetalLB
- **TLS**: cert-manager with Let's Encrypt

### Version Compatibility Matrix

| K8s Version | MetalLB | Kong | cert-manager | Longhorn | ArgoCD |
|-------------|---------|------|--------------|----------|--------|
| 1.25+ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1.24 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1.23 | ⚠️ | ✅ | ✅ | ✅ | ✅ |

## Update Strategy

### Before Updating Components
1. **Backup Critical Data**: Longhorn snapshots, ArgoCD configs
2. **Check Compatibility**: Verify K8s version compatibility
3. **Test in Staging**: Update staging environment first
4. **Review Breaking Changes**: Check component changelogs

### Update Procedure
```bash
# 1. Update component versions in stack file
vim deployment/stacks/cicd-stack.yml

# 2. Backup current state
kubectl get all -A > backup-$(date +%Y%m%d).yaml

# 3. Run deployment
ansible-playbook -i inventory stack_deployment.yml \
  -e stack_file=../deployment/stacks/cicd-stack.yml \
  --diff

# 4. Verify deployment
./deployment/scripts/health-check.sh

# 5. Update this file with new versions
```

## Configuration Changes Log

### 2025-07-19
- **Changed**: NGINX → Kong Gateway for better API management
- **Added**: Wildcard certificate strategy (2 certs total)
- **Modified**: All ingress resources to use Kong annotations
- **Created**: Automated certificate copying scripts

## Known Issues and Workarounds

### MetalLB
- **Issue**: Slow IP assignment on some cloud providers
- **Workaround**: Wait 2-3 minutes after deployment

### Kong Gateway  
- **Issue**: DB-less mode requires restart for some config changes
- **Workaround**: Use kubectl rollout restart deployment/kong-kong -n kong

### cert-manager
- **Issue**: Let's Encrypt rate limits with many certificates
- **Solution**: Using wildcard certificates reduces requests

### Longhorn
- **Issue**: Requires sufficient storage on nodes
- **Workaround**: Ensure at least 10GB free space per node

## Rollback Procedures

### Emergency Rollback
If deployment fails:
```bash
# 1. Rollback to previous Helm releases
helm list -A
helm rollback <release> <revision> -n <namespace>

# 2. Restore from backup if needed
kubectl apply -f backup-<date>.yaml

# 3. Verify services
./deployment/scripts/health-check.sh
```

### Component-Specific Rollbacks
```bash
# Kong Gateway
helm rollback kong -n kong

# ArgoCD  
helm rollback argocd -n argocd

# Longhorn (careful with data)
helm rollback longhorn -n longhorn-system

# cert-manager
helm rollback cert-manager -n cert-manager

# MetalLB
helm rollback metallb -n metallb-system
```

## Future Planning

### Planned Additions
- [ ] Harbor Registry integration
- [ ] Jenkins CI/CD pipelines  
- [ ] Monitoring stack (Prometheus/Grafana)
- [ ] Backup automation for Longhorn
- [ ] RBAC implementation
- [ ] Network policies

### Monitoring and Alerts
- [ ] Set up cluster monitoring
- [ ] Certificate expiry alerts
- [ ] Storage usage alerts
- [ ] Service health checks

## Contact and Support

### Key Resources
- **Documentation**: deployment/README.md
- **Quick Start**: deployment/QUICKSTART.md
- **Health Check**: deployment/scripts/health-check.sh
- **Component Docs**: 
  - Kong: https://docs.konghq.com/
  - ArgoCD: https://argo-cd.readthedocs.io/
  - Longhorn: https://longhorn.io/docs/
  - cert-manager: https://cert-manager.io/docs/

### Emergency Contacts
- **Primary**: admin@bitsb.dev
- **Escalation**: [Add team contacts]

---
**📝 Remember to update this file after each deployment or major change!**
