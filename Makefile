.PHONY: help init plan apply destroy kubeconfig backup restore

help:
	@echo "Available commands:"
	@echo "  make init         - Initialize Terraform"
	@echo "  make plan         - Plan infrastructure"
	@echo "  make apply        - Deploy everything"
	@echo "  make destroy      - Destroy infrastructure"
	@echo "  make kubeconfig   - Get kubeconfig from cluster"
	@echo "  make backup       - Run etcd backup"
	@echo "  make restore      - Restore from backup"

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve
	@echo "✅ Cluster deployed!"
	@echo "Run 'make kubeconfig' to access the cluster"

destroy:
	cd terraform && terraform destroy -auto-approve

kubeconfig:
	@MASTER_IP=$$(cd terraform && terraform output -raw master_ip); \
	ssh -o StrictHostKeyChecking=no azureuser@$$MASTER_IP "sudo cat /etc/kubernetes/admin.conf" > kubeconfig.yaml
	@echo "✅ kubeconfig saved to kubeconfig.yaml"
	@echo "Run: export KUBECONFIG=$$PWD/kubeconfig.yaml"

backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh

argocd-password:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

grafana-url:
	@MASTER_IP=$$(cd terraform && terraform output -raw master_ip); \
	echo "Grafana URL: http://$$MASTER_IP:32000"