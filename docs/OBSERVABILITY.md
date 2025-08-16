# Observability Plan

**Status**: Not implemented yet

## Current Monitoring

- ArgoCD: https://argocd.cicd.bitsb.dev (app health/sync status)
- Longhorn: https://longhorn.cicd.bitsb.dev (storage monitoring)
- Kubernetes: `kubectl` commands for pod/resource status

## Planned Stack

- **kube-prometheus-stack**: Prometheus + Grafana + AlertManager
- **Loki**: Log aggregation
- **Tempo**: Distributed tracing

## Future Structure

```
argocd/appsets/observability/
└── observability-appset.yaml

argocd/values/observability/
├── kube-prometheus-stack/values.yaml
├── loki/values.yaml
└── tempo/values.yaml
```

Will monitor: Infrastructure components, CI/CD services, application metrics, cluster resources.
- Collect metrics from all platform components
- Store time-series data with labels for querying
- Provide PromQL query language for metrics analysis
- Support federation for multi-cluster monitoring

**Planned Configuration**: `argocd/values/observability/prometheus/values.yaml`

**Key Concepts**:
- **Metrics**: Numerical measurements over time (CPU, memory, request rate)
- **Labels**: Key-value pairs that identify metric dimensions
- **Scraping**: Process of collecting metrics from targets
- **PromQL**: Query language for retrieving and analyzing metrics

#### Example Metrics to Monitor
```promql
# Infrastructure metrics
node_cpu_seconds_total
node_memory_MemAvailable_bytes
kubernetes_pod_restart_total

# Application metrics
http_requests_total
http_request_duration_seconds
harbor_registry_image_pulls_total
jenkins_builds_total

# Platform metrics
argocd_app_sync_total
vault_unsealed
cert_manager_certificate_expiration_timestamp_seconds
```

### 📊 Grafana (Visualization and Dashboards)
**Purpose**: Create dashboards and visualizations for metrics and logs

**What it will do**:
- Provide web-based dashboards for metrics visualization
- Create alerts based on metric thresholds
- Support multiple data sources (Prometheus, Loki, Tempo)
- Enable team collaboration with shared dashboards

**Planned Access**: https://grafana.cicd.bitsb.dev
**Planned Configuration**: `argocd/values/observability/grafana/values.yaml`

**Key Concepts**:
- **Dashboards**: Collections of panels showing different metrics
- **Panels**: Individual charts, graphs, or tables
- **Data Sources**: Backend systems that provide data (Prometheus, Loki)
- **Alerts**: Notifications when metrics cross thresholds

#### Planned Dashboard Categories
```yaml
# Infrastructure Dashboards
- Kubernetes Cluster Overview
- Node Resource Usage
- Storage Performance (Longhorn)
- Network Traffic (Kong/Cilium)

# Platform Dashboards  
- ArgoCD Operations
- Vault Performance
- Certificate Expiration
- Backup Success Rate (Velero)

# Application Dashboards
- Harbor Registry Usage
- Jenkins Build Performance
- Authentik Authentication
- Custom Application Metrics
```

### 📝 Loki (Log Aggregation)
**Purpose**: Centralized log collection, storage, and searching

**What it will do**:
- Collect logs from all pods and containers
- Index logs by labels (namespace, pod, container)
- Provide LogQL query language for log searching
- Integrate with Grafana for log visualization

**Planned Configuration**: `argocd/values/observability/loki/values.yaml`

**Key Concepts**:
- **Log Aggregation**: Collecting logs from multiple sources
- **Labels**: Metadata attached to log streams
- **LogQL**: Query language for searching and filtering logs
- **Streams**: Sequences of log entries with same labels

#### Example Log Queries
```logql
# All logs from ArgoCD namespace
{namespace="argocd"}

# Error logs from Harbor
{namespace="harbor"} |= "ERROR"

# Jenkins build logs
{namespace="jenkins", container="jenkins"} | json | job="build"

# Authentication failures
{namespace="authentik"} |= "authentication failed"
```

### 🔍 Tempo (Distributed Tracing)
**Purpose**: Track requests as they flow through multiple services

**What it will do**:
- Trace requests across microservices
- Identify performance bottlenecks
- Visualize service dependencies
- Correlate traces with metrics and logs

**Planned Configuration**: `argocd/values/observability/tempo/values.yaml`

**Key Concepts**:
- **Traces**: Complete journey of a request through system
- **Spans**: Individual operations within a trace
- **Service Map**: Visual representation of service dependencies
- **Sampling**: Collecting subset of traces for performance

### 🚨 AlertManager (Alert Management)
**Purpose**: Handle alerts from Prometheus and other sources

**What it will do**:
- Receive alerts from Prometheus rules
- Group, route, and silence alerts
- Send notifications via multiple channels
- Provide web interface for alert management

**Planned Configuration**: `argocd/values/observability/alertmanager/values.yaml`

**Key Concepts**:
- **Alert Rules**: Conditions that trigger alerts
- **Routing**: Directing alerts to appropriate teams
- **Silencing**: Temporarily suppressing alerts
- **Inhibition**: Preventing duplicate alerts

## 📐 Planned Architecture

### Data Flow
```
Applications → Metrics → Prometheus → Grafana (Dashboards)
            → Logs → Loki → Grafana (Log Search)  
            → Traces → Tempo → Grafana (Tracing)
            
Prometheus → AlertManager → Notifications (Slack, Email, PagerDuty)
```

### Storage Architecture
```yaml
# Metrics Storage (Prometheus)
prometheus:
  storage:
    tsdb:
      retention: 30d
      size: 50Gi

# Log Storage (Loki)  
loki:
  storage:
    retention: 14d
    size: 100Gi

# Trace Storage (Tempo)
tempo:
  storage:
    retention: 7d
    size: 20Gi
```

## 🔧 Current Monitoring Capabilities

### Basic Health Monitoring

#### ArgoCD Application Status
```bash
# Check all application health
kubectl get applications -n argocd

# Monitor sync status
watch kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

# View application details
argocd app get <app-name>
```

#### Kubernetes Resource Monitoring
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -A

# Check pod status across namespaces
kubectl get pods -A | grep -v Running

# Monitor events
kubectl get events -A --sort-by='.lastTimestamp'
```

#### Infrastructure Component Health
```bash
# Storage health (Longhorn)
kubectl get pods -n longhorn-system
curl -k https://longhorn.cicd.bitsb.dev/v1/nodes

# Network health (Kong)
kubectl get pods -n kong
kubectl get svc -n kong kong-proxy

# Certificate health
kubectl get certificates -A
kubectl describe certificate <cert-name> -n <namespace>

# Backup health (Velero)
kubectl get pods -n velero
velero backup get
```

### Application-Specific Monitoring
```bash
# Harbor health
kubectl get pods -n harbor
curl -k https://harbor.cicd.bitsb.dev/api/v2.0/systeminfo

# Jenkins health
kubectl get pods -n jenkins
curl -k https://jenkins.cicd.bitsb.dev/api/json

# Authentik health
kubectl get pods -n authentik
curl -k https://authentik.cicd.bitsb.dev/api/v3/admin/system/

# Vault health
kubectl exec -n vault vault-0 -- vault status
```

## 🚀 Implementation Roadmap

### Phase 1: Basic Metrics (Planned)
- Deploy Prometheus for metrics collection
- Configure Grafana with basic dashboards
- Set up AlertManager for critical alerts
- Monitor infrastructure components

### Phase 2: Advanced Observability (Planned)
- Deploy Loki for log aggregation
- Add Tempo for distributed tracing
- Create application-specific dashboards
- Implement custom metrics for applications

### Phase 3: Advanced Analytics (Future)
- Add Jaeger for advanced tracing
- Implement anomaly detection
- Create capacity planning dashboards
- Add business metrics monitoring

## 🔧 Troubleshooting Without Full Observability

### Infrastructure Issues

#### Storage Problems
```bash
# Check Longhorn health
kubectl get pods -n longhorn-system
kubectl get volumeattachments
kubectl describe pv <pv-name>

# Check PVC status
kubectl get pvc -A | grep -v Bound
kubectl describe pvc <pvc-name> -n <namespace>
```

#### Network Issues
```bash
# Check LoadBalancer services
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Test ingress connectivity
curl -k https://<service>.cicd.bitsb.dev/health

# Check DNS resolution
nslookup <service>.cicd.bitsb.dev
```

#### Certificate Issues
```bash
# Check certificate status
kubectl get certificates -A | grep -v True

# Verify certificate details
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Application Issues

#### GitOps Sync Problems
```bash
# Check ArgoCD application status
kubectl get applications -n argocd -o wide

# View sync errors
argocd app get <app-name> -o yaml

# Manual sync
argocd app sync <app-name>
```

#### CI/CD Pipeline Issues
```bash
# Jenkins build failures
kubectl logs -n jenkins <jenkins-pod>
curl -k https://jenkins.cicd.bitsb.dev/api/json?tree=jobs[name,lastBuild[result,timestamp]]

# Harbor registry issues
kubectl logs -n harbor -l component=core
docker login harbor.cicd.bitsb.dev

# Authentication problems
kubectl logs -n authentik <authentik-pod>
```

## 📊 Metrics to Monitor (When Implemented)

### Infrastructure Metrics
```yaml
# Resource Usage
- node_cpu_usage_seconds_total
- node_memory_usage_bytes
- node_filesystem_usage_bytes

# Kubernetes Health
- kube_pod_status_phase
- kube_deployment_status_replicas
- kube_service_status_load_balancer_ingress

# Storage Performance
- longhorn_volume_actual_size_bytes
- longhorn_volume_state
- longhorn_node_storage_usage_bytes

# Network Performance
- kong_http_requests_total
- kong_request_latency_ms
- cilium_forwarding_errors_total
```

### Application Metrics
```yaml
# ArgoCD Operations
- argocd_app_sync_total
- argocd_app_health_status
- argocd_app_reconcile_count

# Harbor Registry
- harbor_project_quota_usage_byte
- harbor_registry_image_pulled
- harbor_scan_requests_total

# Jenkins Builds
- jenkins_builds_duration_milliseconds_summary
- jenkins_builds_success_build_count
- jenkins_queue_size_value

# Vault Operations
- vault_token_lookup_count
- vault_secret_kv_count
- vault_core_unsealed
```

## 🚨 Alerting Strategy (Planned)

### Critical Alerts (Page Immediately)
```yaml
alerts:
  # Infrastructure Critical
  - name: NodeDown
    condition: up{job="kubernetes-nodes"} == 0
    severity: critical
    
  - name: PodCrashLooping
    condition: rate(kube_pod_container_status_restarts_total[5m]) > 0
    severity: critical
    
  # Platform Critical  
  - name: ArgocdSyncFailing
    condition: argocd_app_sync_total{phase!="Succeeded"} > 0
    severity: critical
    
  - name: VaultSealed
    condition: vault_core_unsealed == 0
    severity: critical
```

### Warning Alerts (Monitor Closely)
```yaml
alerts:
  # Resource Usage
  - name: HighCPUUsage
    condition: node_cpu_usage > 80
    severity: warning
    
  - name: HighMemoryUsage
    condition: node_memory_usage > 85
    severity: warning
    
  # Certificate Expiry
  - name: CertificateExpiringSoon
    condition: cert_manager_certificate_expiration_timestamp_seconds - time() < 7*24*3600
    severity: warning
```

## 🚀 Future Enhancements

### Advanced Monitoring Features
- **SLI/SLO Monitoring**: Track service level indicators and objectives
- **Capacity Planning**: Predict resource needs based on trends
- **Anomaly Detection**: Machine learning-based anomaly detection
- **Business Metrics**: Monitor business KPIs alongside technical metrics

### Integration Opportunities
- **ChatOps**: Slack/Teams integration for alerts and queries
- **Incident Management**: PagerDuty/Opsgenie integration
- **Documentation**: Automatic runbook generation
- **Cost Monitoring**: Track resource costs and optimization opportunities

## 🔗 External Monitoring Integration

### Cloud Provider Integration
```yaml
# AWS CloudWatch integration
- cloudwatch_exporter for AWS metrics
- ELB/ALB metrics for external load balancers
- RDS metrics for external databases

# Azure Monitor integration  
- azure_exporter for Azure metrics
- Application Insights integration
- Log Analytics workspace connection

# GCP Monitoring integration
- stackdriver_exporter for GCP metrics
- Cloud Logging integration
- Cloud Trace connection
```

### Third-Party Service Monitoring
```yaml
# External service monitoring
- blackbox_exporter for endpoint monitoring
- snmp_exporter for network devices
- node_exporter for bare metal hosts
- custom exporters for proprietary systems
```

## 📈 Observability Best Practices

### Metrics Best Practices
- **Use Labels Wisely**: Don't create high cardinality labels
- **Monitor SLIs**: Focus on user-impacting metrics
- **Set Meaningful Alerts**: Avoid alert fatigue
- **Document Everything**: Clear descriptions for all metrics

### Logging Best Practices
- **Structured Logging**: Use JSON format for better parsing
- **Consistent Fields**: Standardize field names across services
- **Appropriate Levels**: Use log levels consistently
- **Sensitive Data**: Never log secrets or PII

### Alerting Best Practices
- **Alert on Symptoms**: Focus on user impact, not root causes
- **Actionable Alerts**: Every alert should require action
- **Clear Runbooks**: Provide clear remediation steps
- **Regular Reviews**: Tune alerts based on feedback

---

**Need help?**
- 📖 **Back to main guide**: [README.md](../README.md)
- 🏗️ **Infrastructure setup**: [Infrastructure Guide](INFRASTRUCTURE.md)
- 🔄 **CI/CD setup**: [CI/CD Guide](CICD.md)

**Ready to implement observability?** The infrastructure and CI/CD layers provide a solid foundation for adding comprehensive monitoring, logging, and alerting capabilities.
