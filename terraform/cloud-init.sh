#!/bin/bash
set -e

# Variables passed from Terraform
admin_username="${admin_username}"

# Install container runtime
apt-get update
apt-get install -y containerd
systemctl enable containerd
systemctl start containerd

# Install kubeadm, kubelet, kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=1.28.0-1.1 kubeadm=1.28.0-1.1 kubectl=1.28.0-1.1
apt-mark hold kubelet kubeadm kubectl

# Configure sysctl
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

if [ "${role}" = "master" ]; then
  # Initialize cluster with pod CIDR
  kubeadm init --pod-network-cidr=192.168.0.0/16
  
  # Configure kubectl
  mkdir -p /home/${admin_username}/.kube
  cp /etc/kubernetes/admin.conf /home/${admin_username}/.kube/config
  chown -R ${admin_username}:${admin_username} /home/${admin_username}/.kube
  
  # Install Calico
  su - ${admin_username} -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26/manifests/calico.yaml"
  
  # Create join command for workers
  kubeadm token create --print-join-command > /home/${admin_username}/join-command.sh
  chmod +x /home/${admin_username}/join-command.sh
  
  # Wait for Calico to be ready
  sleep 60
else
  # Worker nodes - they will join via the master
  # In production, you'd pass the join command from master
  sleep 120
fi