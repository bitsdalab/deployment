# CI/CD Setup

Components deployed via `cicd` ApplicationSet:

- **Authentik 2024.8.3**: SSO for `*.cicd.bitsb.dev` services
- **Harbor 1.15.0**: Container registry with security scanning  
- **Jenkins 5.7.15**: CI/CD automation server

## Access URLs

- Authentik: https://authentik.cicd.bitsb.dev
- Harbor: https://harbor.cicd.bitsb.dev (admin/Harbor12345)
- Jenkins: https://jenkins.cicd.bitsb.dev (admin/admin123)

## Key Files

```
argocd/appsets/cicd/
└── cicd-appset.yaml

argocd/values/cicd/
├── authentik/values.yaml    # SSO configuration
├── harbor/values.yaml       # Registry with RWX storage
└── jenkins/values.yaml      # Build server config
```

## Authentik Configuration

Initial setup: Navigate to `/if/flow/initial-setup/` on first visit
Provides SSO for Harbor, Jenkins, and other platform tools
Supports OIDC/SAML integration

## Harbor Configuration

Uses RWX storage for rolling updates
Built-in vulnerability scanning
Container image signing capabilities
Integrates with Authentik for SSO

## Jenkins Configuration

Pipeline as Code support
Plugin ecosystem for CI/CD workflows
Distributed builds capability
Integrates with Harbor for image builds

## 🎯 Your CI/CD Stack

Your platform deploys these specific CI/CD components:

```
CICD ApplicationSet manages:
├── authentik (2024.8.3)           # SSO for cicd.bitsb.dev
├── harbor (1.15.0)                # Container registry with scanning
└── jenkins (5.7.15)               # CI/CD automation server
```

## 📁 Your Repository Structure

```
argocd/
├── appsets/cicd/
│   └── cicd-appset.yaml           # Main CI/CD ApplicationSet
├── values/cicd/                   # Helm customizations
│   ├── authentik/values.yaml      # SSO configuration
│   ├── harbor/values.yaml         # Registry with RWX storage
│   └── jenkins/values.yaml        # Build server config
```

## � Your Specific Configurations

### 🔐 Authentik (SSO Provider)

**Your Setup**: Centralized authentication for all `*.cicd.bitsb.dev` services

**Access**: https://authentik.cicd.bitsb.dev
**Initial Setup**: Navigate to `/if/flow/initial-setup/` on first visit
**Default Admin**: Create during initial setup

**Your Configuration** (`argocd/values/cicd/authentik/values.yaml`):
```yaml
authentik:
  secret_key: "<generated-during-deployment>"
  postgresql:
    password: "<generated-during-deployment>"
server:
  ingress:
    enabled: true
    hosts:
      - host: authentik.cicd.bitsb.dev
        paths:
          - path: "/"
            pathType: Prefix
```

**What Authentik Manages**:
- SSO for Harbor, Jenkins, and other tools
- User authentication and authorization
- OIDC/SAML integration capabilities
- API tokens for service-to-service auth

**Key Concepts**:
- **SSO (Single Sign-On)**: Log in once, access all tools
- **Identity Provider (IdP)**: Central service that manages user identities
- **SAML/OAuth**: Protocols for secure authentication between services
- **Groups**: Collections of users with similar permissions

### 🐳 Harbor (Container Registry)
**Purpose**: Secure storage and management of container images

**What it does**:
- Stores Docker/OCI container images
- Scans images for security vulnerabilities
- Signs images for supply chain security
- Provides role-based access control

**Access**: https://harbor.cicd.bitsb.dev
**Default Credentials**: admin / Harbor12345
**Configuration**: `argocd/values/cicd/harbor/values.yaml`

```bash
# Check Harbor pods
kubectl get pods -n harbor

# View Harbor services
kubectl get svc -n harbor

# Check storage usage
kubectl get pvc -n harbor
```

**Key Concepts**:
- **Container Registry**: Repository for storing container images
- **Vulnerability Scanning**: Automated security analysis of images
- **Image Signing**: Cryptographic verification of image authenticity
- **Projects**: Logical grouping of repositories with access controls

#### Using Harbor Registry
```bash
# Login to Harbor
docker login harbor.cicd.bitsb.dev
# Username: admin
# Password: Harbor12345

# Tag and push an image
docker tag my-app:latest harbor.cicd.bitsb.dev/library/my-app:v1.0.0
docker push harbor.cicd.bitsb.dev/library/my-app:v1.0.0

# Pull an image
docker pull harbor.cicd.bitsb.dev/library/my-app:v1.0.0
```

### 🔨 Jenkins (CI/CD Automation)
**Purpose**: Automated build, test, and deployment pipelines

**What it does**:
- Builds applications from source code
- Runs automated tests
- Creates and pushes container images
- Triggers deployments via GitOps
- Provides pipeline visualization and logs

**Access**: https://jenkins.cicd.bitsb.dev
**Default Credentials**: admin / admin123
**Configuration**: `argocd/values/cicd/jenkins/values.yaml`

```bash
# Check Jenkins pod
kubectl get pods -n jenkins

# View Jenkins service
kubectl get svc -n jenkins

# Check persistent storage
kubectl get pvc -n jenkins
```

**Key Concepts**:
- **Pipeline**: Automated sequence of build/test/deploy steps
- **Agent**: Worker that executes pipeline steps
- **Jenkinsfile**: Code that defines pipeline steps
- **Webhook**: Automatic trigger when code changes

#### Example Jenkinsfile
```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t my-app:${BUILD_NUMBER} .'
            }
        }
        
        stage('Test') {
            steps {
                sh 'docker run --rm my-app:${BUILD_NUMBER} npm test'
            }
        }
        
        stage('Push to Harbor') {
            steps {
                sh '''
                    docker tag my-app:${BUILD_NUMBER} harbor.cicd.bitsb.dev/library/my-app:${BUILD_NUMBER}
                    docker push harbor.cicd.bitsb.dev/library/my-app:${BUILD_NUMBER}
                '''
            }
        }
        
        stage('Update GitOps') {
            steps {
                sh '''
                    git clone https://github.com/yourusername/deployment.git
                    cd deployment
                    sed -i "s|image: harbor.cicd.bitsb.dev/library/my-app:.*|image: harbor.cicd.bitsb.dev/library/my-app:${BUILD_NUMBER}|" k8s/my-app.yaml
                    git commit -am "Update my-app to ${BUILD_NUMBER}"
                    git push
                '''
            }
        }
    }
}
```

### 🤖 ArgoCD (GitOps Deployment)
**Purpose**: Automated deployment based on Git repository state

**What it does**:
- Monitors Git repositories for changes
- Automatically deploys applications when code changes
- Provides deployment visualization and status
- Enables rollback to previous versions
- Manages application lifecycle

**Access**: https://argocd.cicd.bitsb.dev
**Configuration**: Managed via [bitsdalab/infra](https://github.com/bitsdalab/infra) repository

**Key Concepts**:
- **GitOps**: Deployment method where Git is the source of truth
- **Application**: Kubernetes resources managed by ArgoCD
- **Sync**: Process of making cluster state match Git state
- **Health**: Status of deployed applications

## 🔄 Complete CI/CD Workflow

### Overview: From Code to Production

1. **Developer pushes code** to Git repository
2. **Jenkins detects change** via webhook
3. **Jenkins builds and tests** application
4. **Jenkins creates container image** and pushes to Harbor
5. **Jenkins updates GitOps repository** with new image tag
6. **ArgoCD detects GitOps change** and deploys to cluster
7. **Application is running** with automatic monitoring

### Setting Up a New Application

#### 1. Prepare Your Application
```bash
# Create Dockerfile
cat > Dockerfile << EOF
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Create Jenkinsfile (see example above)
```

#### 2. Create Kubernetes Manifests
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: harbor.cicd.bitsb.dev/library/my-app:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
```

#### 3. Create ArgoCD Application
```yaml
# argocd/applications/my-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/deployment.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## ⚙️ Configuration Management

### CI/CD Values Structure
```
argocd/values/cicd/
├── authentik/values.yaml         # Identity provider config
├── harbor/values.yaml           # Container registry config
└── jenkins/values.yaml          # Build automation config
```

### Example: Harbor ReadWriteMany Configuration
Harbor is configured to use ReadWriteMany (RWX) volumes for smooth rolling updates:

```yaml
# argocd/values/cicd/harbor/values.yaml
persistence:
  enabled: true
  persistentVolumeClaim:
    registry:
      accessMode: ReadWriteMany    # Allows multiple pods
      size: 20Gi
    jobservice:
      jobLog:
        accessMode: ReadWriteMany  # Allows multiple pods
        size: 1Gi
    database:
      size: 5Gi                   # Database uses RWO for performance
```

This configuration prevents rolling update failures that occur when multiple pods try to mount the same ReadWriteOnce (RWO) volume.

## 🔧 Troubleshooting

### Common CI/CD Issues

#### 1. Harbor rolling update failures
**Symptoms**: New Harbor pods stuck in `ContainerCreating`
**Cause**: ReadWriteOnce volumes can't be mounted by multiple pods

```bash
# Check pod status
kubectl get pods -n harbor

# Check events for mount issues
kubectl describe pod <harbor-pod> -n harbor

# Verify RWX configuration is applied
kubectl get pvc -n harbor -o yaml | grep accessModes
```

**Solution**: Ensure Harbor is configured with ReadWriteMany volumes (see configuration above)

#### 2. Jenkins pipeline failures
**Symptoms**: Builds fail with permission or connectivity errors

```bash
# Check Jenkins logs
kubectl logs -n jenkins <jenkins-pod>

# Test Docker daemon connectivity
kubectl exec -n jenkins <jenkins-pod> -- docker ps

# Check Harbor connectivity
kubectl exec -n jenkins <jenkins-pod> -- curl -k https://harbor.cicd.bitsb.dev/api/v2.0/systeminfo
```

#### 3. Authentication issues
**Symptoms**: Can't log into services, SSO not working

```bash
# Check Authentik status
kubectl get pods -n authentik
kubectl logs -n authentik <authentik-pod>

# Test OIDC connectivity
curl -k https://authentik.cicd.bitsb.dev/.well-known/openid_configuration
```

#### 4. Image pull failures
**Symptoms**: Kubernetes can't pull images from Harbor

```bash
# Check image pull secrets
kubectl get secrets -A | grep harbor

# Test image pull manually
docker pull harbor.cicd.bitsb.dev/library/my-app:latest

# Check Harbor project permissions
```

#### 5. ArgoCD sync failures
**Symptoms**: Applications stuck in `OutOfSync` or `Degraded` state

```bash
# Check application status
kubectl get applications -n argocd

# View detailed application info
argocd app get <app-name>

# Check repository connectivity
argocd repo list
```

### Debug Commands

```bash
# CI/CD overview
kubectl get applications -n argocd | grep cicd
kubectl get pods -A | grep -E "(authentik|harbor|jenkins)"

# Service connectivity
kubectl get svc -A | grep -E "(authentik|harbor|jenkins)"
kubectl get ingress -A | grep -E "(authentik|harbor|jenkins)"

# Storage health (important for Harbor)
kubectl get pvc -A | grep harbor
kubectl describe pvc <pvc-name> -n harbor

# Authentication flow
curl -k https://authentik.cicd.bitsb.dev/api/v3/admin/system/
curl -k https://harbor.cicd.bitsb.dev/api/v2.0/systeminfo

# Registry operations
docker login harbor.cicd.bitsb.dev
docker images | grep harbor.cicd.bitsb.dev
```

## 🔐 Security Best Practices

### Identity and Access Management
- **SSO Integration**: Use Authentik for centralized authentication
- **Role-Based Access**: Configure appropriate permissions in each tool
- **API Tokens**: Use service accounts for automated access
- **Regular Rotation**: Rotate passwords and tokens regularly

### Container Security
- **Image Scanning**: Enable vulnerability scanning in Harbor
- **Image Signing**: Sign images for supply chain security
- **Base Image Updates**: Regularly update base images
- **Secrets Management**: Never embed secrets in images

### Pipeline Security
- **Credential Management**: Store credentials securely in Jenkins
- **Branch Protection**: Require reviews for main branch changes
- **Build Isolation**: Use ephemeral build agents
- **Audit Logging**: Monitor all CI/CD activities

## 📈 Monitoring CI/CD

### Key Metrics
```bash
# Pipeline success rate
# Build duration trends
# Deployment frequency
# Lead time for changes
# Mean time to recovery

# Check Jenkins build history
curl -k https://jenkins.cicd.bitsb.dev/api/json

# Harbor storage usage
kubectl get pvc -n harbor
kubectl exec -n harbor <harbor-core-pod> -- df -h

# ArgoCD sync statistics
argocd app list -o wide
```

### Health Checks
```bash
# All CI/CD services healthy
kubectl get pods -A | grep -E "(authentik|harbor|jenkins)" | grep -v Running

# Certificate validity
kubectl get certificates -A | grep -E "(authentik|harbor|jenkins)"

# Storage availability
kubectl get pvc -A | grep -E "(authentik|harbor|jenkins)" | grep -v Bound
```

## 🚀 Advanced CI/CD Patterns

### Multi-Environment Deployment
```yaml
# Deploy to staging first, then production
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app-environments
spec:
  generators:
  - list:
      elements:
      - env: staging
        cluster: https://kubernetes.default.svc
        namespace: my-app-staging
      - env: production
        cluster: https://prod-cluster-url
        namespace: my-app-production
  template:
    metadata:
      name: 'my-app-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/yourusername/deployment.git
        targetRevision: HEAD
        path: 'environments/{{env}}'
      destination:
        server: '{{cluster}}'
        namespace: '{{namespace}}'
```

### Canary Deployments
```yaml
# Use Argo Rollouts for advanced deployment strategies
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 30s}
      - setWeight: 50
      - pause: {duration: 30s}
  selector:
    matchLabels:
      app: my-app
  template:
    # ... pod template
```

## 🚀 Next Steps

### CI/CD Ready?
Once your CI/CD pipeline is working:

1. **Add Monitoring**: Follow [Observability Guide](OBSERVABILITY.md) for monitoring
2. **Scale Teams**: Set up projects and permissions for multiple teams
3. **Advanced Patterns**: Implement canary deployments, feature flags
4. **External Integrations**: Connect to external systems and APIs

### Integration Examples
- **Slack Notifications**: Get build/deploy notifications in Slack
- **JIRA Integration**: Link commits and builds to JIRA tickets
- **Quality Gates**: Block deployments based on test coverage
- **Compliance**: Implement policy-as-code with OPA Gatekeeper

---

**Need help?**
- 📖 **Back to main guide**: [README.md](../README.md)
- 🏗️ **Infrastructure setup**: [Infrastructure Guide](INFRASTRUCTURE.md)
- 📊 **Monitoring**: [Observability Guide](OBSERVABILITY.md)
