# GitOpsLab - Kubernetes on Azure with GitOps

## Prerequisites

1. **Azure Subscription** with Contributor access
2. **Terraform** (v1.5+)
3. **kubectl** (v1.28+)
4. **Helm** (v3+)
5. **SSH key pair** (`ssh-keygen -t rsa -b 4096`)

## Quick Start

### 1. Configure Azure credentials

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name gitopslab --role Contributor

