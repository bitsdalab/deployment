# CA Certificates for Bare Metal Kubernetes

## Problem
In bare metal Kubernetes clusters, container images often lack CA certificates, causing SSL/TLS verification failures when pods try to connect to external HTTPS services. This manifests as errors like:
- `certificate verify failed: unable to get local issuer certificate`
- `x509: certificate signed by unknown authority`
- `SSL: CERTIFICATE_VERIFY_FAILED`

## Solution: Simple hostPath Volume Mounts

The simplest solution is to mount the host's CA certificates directly into pods using hostPath volumes.

### For Individual Pods

Add this to any pod specification:

```yaml
spec:
  containers:
  - name: your-container
    image: your-image
    volumeMounts:
    - name: ca-certificates
      mountPath: /etc/ssl/certs
      readOnly: true
  volumes:
  - name: ca-certificates
    hostPath:
      path: /etc/ssl/certs
      type: Directory
```

### For Helm Charts (like ArgoCD)

Add this to your `values.yaml`:

```yaml
server:
  volumes:
    - name: ca-certificates
      hostPath:
        path: /etc/ssl/certs
        type: Directory
  
  volumeMounts:
    - name: ca-certificates
      mountPath: /etc/ssl/certs
      readOnly: true

controller:
  volumes:
    - name: ca-certificates
      hostPath:
        path: /etc/ssl/certs
        type: Directory
  
  volumeMounts:
    - name: ca-certificates
      mountPath: /etc/ssl/certs
      readOnly: true

repoServer:
  volumes:
    - name: ca-certificates
      hostPath:
        path: /etc/ssl/certs
        type: Directory
  
  volumeMounts:
    - name: ca-certificates
      mountPath: /etc/ssl/certs
      readOnly: true
```

## Why This Works

1. **Host CA certificates**: The Kubernetes nodes have proper CA certificates installed in `/etc/ssl/certs/`
2. **Container access**: Mounting this directory into containers gives them access to the same trusted CAs
3. **No additional setup**: No ConfigMaps, scripts, or complex configurations needed
4. **Standard paths**: Applications expect CA certificates in `/etc/ssl/certs/`

## Security Considerations

- This approach mounts the entire CA certificate directory read-only
- Pods cannot modify the host's CA certificates
- Only provides access to public CA certificates, not private keys
- Standard practice for bare metal Kubernetes clusters

## Testing

To test if a pod can now connect to HTTPS services:

```bash
# Run a test pod
kubectl run ca-test --rm -it --image=ubuntu --restart=Never --overrides='
{
  "spec": {
    "containers": [
      {
        "name": "ca-test",
        "image": "ubuntu",
        "command": ["bash"],
        "volumeMounts": [
          {
            "name": "ca-certificates",
            "mountPath": "/etc/ssl/certs",
            "readOnly": true
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "ca-certificates",
        "hostPath": {
          "path": "/etc/ssl/certs",
          "type": "Directory"
        }
      }
    ]
  }
}' -- bash

# Inside the pod, test HTTPS connectivity
apt update && apt install -y curl
curl -I https://github.com  # Should work without SSL errors
```

## Applied To

This configuration has been applied to:
- ✅ ArgoCD server component
- ✅ ArgoCD application controller  
- ✅ ArgoCD repository server
- ✅ Kubernetes cluster setup (CA certificates package installation)

## Files Modified

- `infra/ansible/playbooks/simple_k8s_cluster.yml` - Added ca-certificates package installation
- `deployment/stacks/values/argocd/values.yaml` - Added hostPath volume mounts for CA certificates
- `deployment/stacks/base/ca-certificates.yaml` - Example configuration for other deployments
