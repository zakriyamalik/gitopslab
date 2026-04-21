#!/bin/bash
set -e

BACKUP_DIR="/var/backups/etcd"
DATE=$(date +%Y%m%d-%H%M%S)
MASTER_IP=$(cd terraform && terraform output -raw master_ip)

echo "📦 Starting backup at $DATE"

# Create backup directory on master
ssh azureuser@$MASTER_IP "sudo mkdir -p $BACKUP_DIR"

# etcd backup
echo "💾 Backing up etcd..."
ssh azureuser@$MASTER_IP << EOF
  sudo ETCDCTL_API=3 etcdctl snapshot save $BACKUP_DIR/etcd-snapshot-$DATE.db \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key
EOF

# Backup all Kubernetes resources
echo "📋 Backing up Kubernetes resources..."
kubectl get all --all-namespaces -o yaml > all-resources-$DATE.yaml
kubectl get pv,pvc,configmap,secret,ingress -A -o yaml >> all-resources-$DATE.yaml

# Backup critical manifests
echo "🔐 Backing up critical data..."
mkdir -p backup-$DATE
cp -r k8s/ backup-$DATE/
cp terraform/terraform.tfvars backup-$DATE/ 2>/dev/null || true

# Create archive
tar -czf full-backup-$DATE.tar.gz backup-$DATE/ all-resources-$DATE.yaml

# Cleanup
rm -rf backup-$DATE
rm all-resources-$DATE.yaml

echo "✅ Backup complete: full-backup-$DATE.tar.gz"
echo "📁 etcd snapshot: $BACKUP_DIR/etcd-snapshot-$DATE.db on master"