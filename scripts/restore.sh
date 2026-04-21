#!/bin/bash
set -e

SNAPSHOT=$1

if [ -z "$SNAPSHOT" ]; then
  echo "Usage: ./restore.sh <snapshot-file>"
  echo "Example: ./restore.sh etcd-snapshot-20240101-120000.db"
  exit 1
fi

MASTER_IP=$(cd terraform && terraform output -raw master_ip)

echo "⚠️  WARNING: This will restore cluster from $SNAPSHOT"
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelled"
  exit 1
fi

echo "🔄 Restoring cluster from $SNAPSHOT..."

ssh azureuser@$MASTER_IP << EOF
  # Stop kube-apiserver
  sudo systemctl stop kube-apiserver
  
  # Restore etcd
  sudo ETCDCTL_API=3 etcdctl snapshot restore $SNAPSHOT \
    --data-dir=/var/lib/etcd-restored
    
  # Replace etcd data
  sudo mv /var/lib/etcd-restored /var/lib/etcd
  sudo chown -R etcd:etcd /var/lib/etcd
  
  # Restart services
  sudo systemctl start etcd kube-apiserver
EOF

echo "✅ Cluster restored successfully!"
echo "Verify with: kubectl get nodes"