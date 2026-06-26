output "ansible_inventory" {
  description = "Ansible inventory for Terraform-managed service nodes."
  value       = module.nodes.ansible_inventory
}
