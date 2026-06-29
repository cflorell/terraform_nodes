module "nodes" {
  source = "./nodes"

  vm_password                        = var.vm_password
  vm_ssh_public_keys                 = var.vm_ssh_public_keys
  runner_vm_cloud_image_url          = var.runner_vm_cloud_image_url
  runner_vm_cloud_image_file_name    = var.runner_vm_cloud_image_file_name
  runner_vm_cloud_image_datastore_id = var.runner_vm_cloud_image_datastore_id
  runner_vm_datastore_id             = var.runner_vm_datastore_id
  runner_vm_ipv4_address             = var.runner_vm_ipv4_address
  runner_vm_ipv4_gateway             = var.runner_vm_ipv4_gateway

  providers = {
    proxmox = proxmox
  }
}
