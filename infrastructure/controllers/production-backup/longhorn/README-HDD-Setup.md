# Adding Capacity Tier Storage to Longhorn Master Node

This guide will help you add a new HDD disk for capacity tier storage to your master node in Longhorn.

## Storage Tier Overview

- **Performance Tier (SSD)**: High-performance storage for databases, configs, and frequently accessed data
- **Capacity Tier (HDD)**: High-capacity storage for bulk data, media, archives, and backups

## Prerequisites

1. Physical HDD is connected to your master node
2. You have root/sudo access to the master node
3. Longhorn is already installed and running

## Step 1: Prepare the Physical Disk

### 1.1 Identify the new disk
```bash
# List all available disks
sudo fdisk -l

# Or use lsblk to see block devices
lsblk
```

### 1.2 Create a partition (if needed)
```bash
# Replace /dev/sdX with your actual disk
sudo fdisk /dev/sdX

# In fdisk:
# - Press 'n' for new partition
# - Press 'p' for primary partition
# - Accept defaults for partition number and sectors
# - Press 'w' to write changes
```

### 1.3 Format the disk
```bash
# Format with ext4 filesystem
sudo mkfs.ext4 /dev/sdX1

# Add a label (optional but recommended)
sudo e2label /dev/sdX1 longhorn-capacity
```

### 1.4 Create mount point and mount
```bash
# Create mount directory following standard conventions
sudo mkdir -p /storage/capacity

# Mount the disk
sudo mount /dev/sdX1 /storage/capacity

# Set proper permissions for Longhorn
sudo chown -R root:root /storage/capacity
sudo chmod 755 /storage/capacity
```

### 1.5 Make mount persistent
```bash
# Get the UUID of the disk
sudo blkid /dev/sdX1

# Add to /etc/fstab
echo "UUID=your-disk-uuid /storage/capacity ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Test the fstab entry
sudo umount /storage/capacity
sudo mount -a
```

## Step 2: Update Longhorn Configuration

### 2.1 Update the node name in the configuration
Edit `node-disk-config.yaml` and replace `master-node` with your actual node name:

```bash
# Get your actual node name
kubectl get nodes

# Update the configuration file with the correct node name
```

### 2.2 Apply the configuration
```bash
# From the homelab root directory
kubectl apply -k infrastructure/controllers/production-backup/longhorn/
```

## Step 3: Verify the Setup

### 3.1 Check Longhorn UI
1. Access Longhorn UI at `https://longhorn.justindesio.com`
2. Go to "Node" tab
3. Find your master node and verify the new disk appears
4. Check that both disks show as "Schedulable"

### 3.2 Verify via kubectl
```bash
# Check the node configuration
kubectl get nodes.longhorn.io -n longhorn-system

# Get detailed information about your node
kubectl describe nodes.longhorn.io master-node -n longhorn-system
```

### 3.3 Test the Storage Classes
```bash
# Test the Capacity Tier (HDD) storage class
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-capacity-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-capacity
  resources:
    requests:
      storage: 10Gi
EOF

# Test the Performance Tier (SSD) storage class
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-performance-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-performance
  resources:
    requests:
      storage: 1Gi
EOF

# Check if PVCs are bound
kubectl get pvc test-capacity-pvc test-performance-pvc

# Cleanup test PVCs
kubectl delete pvc test-capacity-pvc test-performance-pvc
```

## Storage Tier Configuration

### **Performance Tier (SSD)**
- **Path**: `/var/lib/longhorn`
- **Replicas**: 2 (high availability)
- **Tags**: `ssd`, `performance`, `tier1`, `hot`
- **Use for**: Databases, configs, OS data, frequently accessed files

### **Capacity Tier (HDD)**  
- **Path**: `/storage/capacity`
- **Replicas**: 1 (cost-efficient)
- **Tags**: `hdd`, `capacity`, `tier2`, `warm`
- **Use for**: Media files, archives, logs, backups, bulk data

## Storage Classes

- **`longhorn`** (default, uses any available disk)
- **`longhorn-performance`** (Performance Tier - SSD only)
- **`longhorn-capacity`** (Capacity Tier - HDD only)

## Use Case Examples

### Performance Tier Workloads
```yaml
# High-performance applications
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
spec:
  storageClassName: longhorn-performance
  # ... rest of spec
```

**Use for:**
- PostgreSQL/MySQL databases
- Redis/Cache layers  
- Application configurations
- Container image storage
- OS and system data

### Capacity Tier Workloads
```yaml
# High-capacity applications
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-storage-pvc
spec:
  storageClassName: longhorn-capacity
  # ... rest of spec
```

**Use for:**
- Nextcloud file storage
- Media server content (Plex, Jellyfin)
- Backup storage
- Log aggregation
- Archive data

## Troubleshooting

### Disk not appearing in Longhorn
1. Check if the disk is properly mounted: `df -h | grep /storage/capacity`
2. Verify permissions: `ls -la /storage/capacity`
3. Check Longhorn manager logs: `kubectl logs -n longhorn-system -l app=longhorn-manager`

### Node not updating
1. Check if the Node CR was applied: `kubectl get nodes.longhorn.io -n longhorn-system`
2. Restart Longhorn manager: `kubectl rollout restart deployment/longhorn-manager -n longhorn-system`

### Storage Class issues
1. Verify the storage classes exist: `kubectl get storageclass longhorn-performance longhorn-capacity`
2. Check if the disk tags match the diskSelector in the StorageClass

## Best Practices

### Performance Optimization
- **Performance Tier**: Use for latency-sensitive workloads requiring high IOPS
- **Capacity Tier**: Use for throughput-oriented workloads with large storage needs

### Cost Optimization
- **Performance Tier**: 2 replicas for critical data protection
- **Capacity Tier**: 1 replica to minimize storage costs

### Data Lifecycle
1. Start new workloads on Performance Tier if unsure
2. Monitor usage patterns and IOPS requirements
3. Migrate stable, large datasets to Capacity Tier
4. Keep frequently accessed data on Performance Tier

## Notes

- Follows industry-standard **Performance/Capacity** tier naming conventions
- Storage path `/storage/capacity` follows Linux filesystem hierarchy standards
- Tags include both specific (`performance`/`capacity`) and generic (`tier1`/`tier2`) identifiers
- Consider implementing automated data lifecycle policies for cost optimization 