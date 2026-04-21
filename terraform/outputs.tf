output "master_ip" {
  description = "Public IP address of master node"
  value       = azurerm_public_ip.master.ip_address
}

output "worker_ips" {
  description = "Private IP addresses of worker nodes"
  value       = azurerm_network_interface.worker[*].private_ip_address
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.rg.name
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.master.ip_address} sudo cat /etc/kubernetes/admin.conf"
}

output "grafana_url" {
  description = "Grafana access URL"
  value       = "http://${azurerm_public_ip.master.ip_address}:32000"
}