# GitOps Deployment Plan

## Overview
Transition from direct Helm deployments to a GitOps approach using ArgoCD as the central orchestrator. This plan outlines the architecture, deployment strategy, and implementation steps.

## Current State
- **Ansible playbook**: `infra/ansible/playbooks/stack_deployment.yml` - Generic Helm deployment playbook
- **Stack config**: `deployment/stacks/cicd-stack.yml` - Currently configured for ArgoCD only
- **Repository structure**: 
  ```
  deployment/
  ├── README.md
  └── stacks/
      └── cicd-stack.yml
  ```

## Target Architecture

### Phase 1: ArgoCD Bootstrap
**Goal**: Deploy ArgoCD as the foundation for GitOps

**Components**:
- ArgoCD server with NodePort access (ports 30080/30443)
- ApplicationSet controller enabled
- Basic RBAC configuration
- No ingress/TLS initially (NodePort only)

**Deployment Method**: 
- Use existing Ansible playbook with ArgoCD-only stack config
- Single command: `ansible-playbook infra/ansible/playbooks/stack_deployment.yml -e stack_file=deployment/stacks/cicd-stack.yml`

### Phase 2: ApplicationSet Structure
**Goal**: Define ApplicationSet patterns for different application categories

**ApplicationSet Categories**:
1. **CICD ApplicationSet** (`appsets/cicd-appset.yaml`)
   - Jenkins
   - Harbor
   - SonarQube (if needed)
   - Nexus (if needed)

2. **Apps Type 1 ApplicationSet** (`appsets/apps-type1-appset.yaml`)
   - Web applications
   - Frontend services
   - Static sites

3. **Apps Type 2 ApplicationSet** (`appsets/apps-type2-appset.yaml`)
   - Backend services
   - APIs
   - Databases

4. **Infrastructure ApplicationSet** (`appsets/infra-appset.yaml`)
   - Monitoring (Prometheus, Grafana)
   - Logging (ELK stack)
   - Security tools
   - Certificate management

### Phase 3: Application Definitions
**Goal**: Create Helm charts or Kustomize configurations for each application

**Directory Structure**:
```
deployment/
├── README.md
├── plan.md
├── stacks/
│   └── cicd-stack.yml          # ArgoCD bootstrap only
├── appsets/
│   ├── cicd-appset.yaml        # CICD tools ApplicationSet
│   ├── apps-type1-appset.yaml  # Application category 1
│   ├── apps-type2-appset.yaml  # Application category 2
│   └── infra-appset.yaml       # Infrastructure tools
└── applications/
    ├── cicd/
    │   ├── jenkins/
    │   │   ├── Chart.yaml
    │   │   ├── values.yaml
    │   │   └── templates/
    │   └── harbor/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    ├── apps-type1/
    │   └── [individual app configs]
    ├── apps-type2/
    │   └── [individual app configs]
    └── infrastructure/
        └── [infra tool configs]
```

## Implementation Steps

### Step 1: ArgoCD Deployment ✅
- [x] Update `cicd-stack.yml` to only include ArgoCD
- [ ] Deploy ArgoCD using Ansible playbook
- [ ] Verify ArgoCD is accessible via NodePort
- [ ] Get admin password and login to ArgoCD UI

### Step 2: Repository Structure Setup
- [ ] Create `appsets/` directory
- [ ] Create `applications/` directory with subdirectories
- [ ] Create initial ApplicationSet templates

### Step 3: CICD ApplicationSet Implementation
- [ ] Create `appsets/cicd-appset.yaml`
- [ ] Create Helm charts for Jenkins and Harbor in `applications/cicd/`
- [ ] Deploy CICD ApplicationSet through ArgoCD
- [ ] Verify Jenkins and Harbor deployments

### Step 4: Expand to Other ApplicationSets
- [ ] Define application categories (Type 1, Type 2, Infrastructure)
- [ ] Create corresponding ApplicationSets
- [ ] Migrate any existing applications to GitOps model

### Step 5: Ingress and TLS Setup (Future)
- [ ] Deploy ingress controller
- [ ] Configure cert-manager
- [ ] Update all applications to use ingress instead of NodePort
- [ ] Enable TLS for ArgoCD and all applications

## Configuration Patterns

### ApplicationSet Template Structure
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cicd-appset
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - name: jenkins
        namespace: cicd
      - name: harbor
        namespace: cicd
  template:
    metadata:
      name: '{{name}}'
    spec:
      project: default
      source:
        repoURL: <repository-url>
        targetRevision: HEAD
        path: applications/cicd/{{name}}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

### Helm Chart Structure for Applications
Each application will have:
- `Chart.yaml` - Helm chart metadata
- `values.yaml` - Default values with NodePort initially, ingress commented
- `templates/` - Kubernetes manifests
- Environment-specific value overrides (dev, staging, prod)

## Benefits of This Approach

1. **GitOps Workflow**: All changes tracked in Git
2. **Declarative**: Infrastructure and applications as code
3. **Scalable**: Easy to add new applications and environments
4. **Consistent**: Same deployment pattern for all applications
5. **Rollback Capable**: Git-based rollback for any component
6. **Self-Healing**: ArgoCD automatically syncs desired state
7. **Multi-Environment**: Easy to replicate across environments

## Decision Points

### ✅ Finalized Decisions:
- Use ArgoCD for GitOps orchestration
- Use ApplicationSets for application grouping
- Start with NodePort, migrate to ingress later
- Keep Ansible playbook for ArgoCD bootstrap only

### 🤔 Pending Decisions:
1. **Repository Strategy**: 
   - Single repo for all applications vs separate repos
   - **Recommendation**: Start with single repo, split later if needed

2. **Application Packaging**:
   - Helm charts vs Kustomize vs raw YAML
   - **Recommendation**: Helm charts for complex apps, Kustomize for simple configs

3. **Environment Strategy**:
   - How to handle dev/staging/prod differences
   - **Recommendation**: Value overrides and branch-based targeting

4. **Secret Management**:
   - How to handle sensitive data (passwords, API keys)
   - **Options**: Sealed Secrets, External Secrets Operator, or Vault integration

## Next Actions

1. **Immediate**: Deploy ArgoCD using current configuration
2. **Short-term**: Create first ApplicationSet for CICD tools
3. **Medium-term**: Migrate Jenkins and Harbor to GitOps model
4. **Long-term**: Expand to all application categories

---

**Status**: Planning Phase  
**Last Updated**: 2025-07-18  
**Next Review**: After ArgoCD deployment
