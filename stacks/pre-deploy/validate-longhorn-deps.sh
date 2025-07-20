#!/bin/bash

# Validation script to check if Longhorn dependencies are installed on all nodes
# This can be referenced in stack YAML as:
# pre_deploy_scripts:
#   - "bash pre-deploy/validate-longhorn-deps.sh"

echo "=== Validating Longhorn Dependencies on All Nodes ==="

# Create a Job to check dependencies on all nodes
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: longhorn-deps-validator
  namespace: kube-system
spec:
  template:
    spec:
      hostPID: true
      hostNetwork: true
      tolerations:
      - operator: Exists
      containers:
      - name: validator
        image: ubuntu:24.04
        securityContext:
          privileged: true
        command:
        - /bin/bash
        - -c
        - |
          echo "=== Validating Longhorn dependencies ==="
          
          # Get all node names
          NODES=\$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
          echo "Checking nodes: \$NODES"
          
          ALL_GOOD=true
          
          for node in \$NODES; do
            echo "Checking node: \$node"
            
            # SSH to node or use kubectl debug (simplified approach)
            if kubectl debug node/\$node -it --image=ubuntu:24.04 -- chroot /host bash -c "
              if command -v iscsiadm >/dev/null 2>&1; then
                echo '✓ iscsiadm is installed on \$node'
                iscsiadm --version | head -1
              else
                echo '✗ iscsiadm is NOT installed on \$node'
                exit 1
              fi
              
              if systemctl is-active --quiet iscsid; then
                echo '✓ iscsid service is running on \$node'
              else
                echo '✗ iscsid service is NOT running on \$node'
                exit 1
              fi
            "; then
              echo "✓ Node \$node is ready for Longhorn"
            else
              echo "✗ Node \$node is NOT ready for Longhorn"
              ALL_GOOD=false
            fi
            echo "---"
          done
          
          if [ "\$ALL_GOOD" = true ]; then
            echo "🎉 All nodes are ready for Longhorn deployment!"
            exit 0
          else
            echo "❌ Some nodes are not ready. Please install dependencies first."
            exit 1
          fi
      restartPolicy: Never
  backoffLimit: 3
EOF

echo "Waiting for validation to complete..."
kubectl wait --for=condition=complete job/longhorn-deps-validator -n kube-system --timeout=300s

echo "Validation results:"
kubectl logs job/longhorn-deps-validator -n kube-system

# Clean up
echo "Cleaning up validator job..."
kubectl delete job longhorn-deps-validator -n kube-system

echo "=== Longhorn dependencies validation completed ==="
