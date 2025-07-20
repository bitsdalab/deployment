#!/bin/bash

# Pre-deployment script to install Longhorn dependencies on all nodes
# This can be referenced in stack YAML as:
# pre_deploy_scripts:
#   - "bash pre-deploy/install-longhorn-deps.sh"

echo "=== Installing Longhorn Dependencies on All Nodes ==="

# Create a DaemonSet to install open-iscsi on all nodes
echo "Creating DaemonSet to install open-iscsi..."

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: longhorn-deps-installer
  namespace: kube-system
  labels:
    app: longhorn-deps-installer
spec:
  selector:
    matchLabels:
      app: longhorn-deps-installer
  template:
    metadata:
      labels:
        app: longhorn-deps-installer
    spec:
      hostPID: true
      hostNetwork: true
      tolerations:
      - operator: Exists
      containers:
      - name: installer
        image: ubuntu:24.04
        securityContext:
          privileged: true
        command:
        - /bin/bash
        - -c
        - |
          echo "=== Installing open-iscsi on node \$(hostname) ==="
          
          # Use nsenter to run commands in host namespace
          nsenter --target 1 --mount --uts --ipc --net --pid -- bash << 'HOSTSCRIPT'
            set -e
            echo "Updating package list..."
            apt-get update -qq
            
            echo "Installing open-iscsi..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y open-iscsi
            
            echo "Enabling iscsid service..."
            systemctl enable iscsid
            systemctl start iscsid
            
            echo "Verifying installation..."
            iscsiadm --version
            
            echo "open-iscsi installed successfully!"
          HOSTSCRIPT
          
          echo "Installation completed on \$(hostname)"
          
          # Create a marker file to indicate completion
          touch /tmp/longhorn-deps-installed
          
          # Keep container running
          sleep infinity
        volumeMounts:
        - name: host-root
          mountPath: /host
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: host-root
        hostPath:
          path: /
      - name: tmp
        hostPath:
          path: /tmp
EOF

echo "Waiting for DaemonSet to be ready..."
kubectl rollout status daemonset/longhorn-deps-installer -n kube-system --timeout=600s

echo "Checking installation logs..."
kubectl logs -l app=longhorn-deps-installer -n kube-system --tail=10

# Wait a bit more to ensure installation completes
sleep 30

echo "Cleaning up installer DaemonSet..."
kubectl delete daemonset longhorn-deps-installer -n kube-system

echo "=== Longhorn dependencies installation completed ==="
echo "You can now deploy Longhorn safely."
