variable "vm_password" {
  description = "Password for Terraform-created VM root users."
  type        = string
  sensitive   = true
}

variable "vm_ssh_public_keys" {
  description = "SSH public keys to install for Terraform-created VM root users."
  type        = list(string)
  default     = []
}

variable "runner_vm_cloud_image_url" {
  description = "Debian cloud image URL used to create the runner VM disk."
  type        = string
}

variable "runner_vm_cloud_image_file_name" {
  description = "File name to use for the runner VM cloud image in Proxmox import storage."
  type        = string
}

variable "runner_vm_cloud_image_datastore_id" {
  description = "Proxmox datastore used to store the downloaded runner cloud image."
  type        = string
}

variable "runner_vm_datastore_id" {
  description = "Proxmox datastore for the runner VM disk and cloud-init disk."
  type        = string
}

variable "runner_vm_ipv4_address" {
  description = "Runner VM IPv4 address in CIDR notation, or dhcp."
  type        = string
}

variable "runner_vm_ipv4_gateway" {
  description = "Runner VM IPv4 gateway. Leave empty when runner_vm_ipv4_address is dhcp."
  type        = string
}
