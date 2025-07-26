# Velero Backup with External MinIO – Multi-Node Setup

This README outlines how to configure Velero to back up your Kubernetes workloads to an **external MinIO server**, with a setup that targets two nodes (`bits-node-1` and `bits-node-2`). This assumes Velero is already installed via Helm and running in your cluster.

---

## 🔐 Secret Credentials

Create the secret used by Velero for authenticating to MinIO:

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

---

## 📦 Backup Storage Locations (BSLs)

Define a `BackupStorageLocation` for each MinIO node:

### bits-node-1 (bucket: `velero`)
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
    s3Url: http://bits-node-2:9000
    insecureSkipTLSVerify: "true"
    insecure: "true"
  credential:
    name: velero-minio-creds
    key: cloud
```

### bits-node-2 (bucket: `velero-bits-node-2`)
```yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: minio-node-2
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero-bits-node-2
  config:
    region: us-east-1
    s3Url: http://bits-node-2:9000
    insecureSkipTLSVerify: "true"
    insecure: "true"
  credential:
    name: velero-minio-creds
    key: cloud
```

---

## 📆 Scheduled Backups (Every 4 Hours)

Create Velero `Schedule` objects for both locations:

### Schedule for bits-node-1
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
    ttl: 240h
    storageLocation: minio-node-1
    snapshotVolumes: false
```

### Schedule for bits-node-2
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
    ttl: 240h
    storageLocation: minio-node-2
    snapshotVolumes: false
```


**Note:**
- If you do **not** want Velero to create volume snapshots (for example, if you use Longhorn for PV management and handle volume backups separately), add `snapshotVolumes: false` to your Schedule and Backup specs. This prevents Velero from attempting to use VolumeSnapshotLocations (VSLs) and avoids validation errors when multiple VSLs exist.
- Adjust the `bucket` names and `s3Url` as per your MinIO node deployment. Ensure your MinIO service is reachable from the Velero pods and the access credentials are valid.

---

## 🚀 Immediate Test: Manual Backup for Each Node (YAML)

To trigger a manual backup immediately (without waiting for the schedule), apply the following YAML manifests for each node:

### Manual Backup to bits-node-1
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

### Manual Backup to bits-node-2
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

Apply with:
```sh
kubectl apply -f <backup-yaml-file>
```

You can check the status of your backups with:
```sh
kubectl -n velero get backup
```
