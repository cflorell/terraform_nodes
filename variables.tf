variable "vm_password" {
  description = "Password for the user"
  type        = string
  sensitive   = true
}

variable "vm_ssh_public_keys" {
  description = <<-EOT
    SSH public keys to install for Terraform-created VM root users,
    including my own workstation, shell- and kubernetes runners.
  EOT
  type        = list(string)
  default     = []
}

variable "runner_vm_cloud_image_url" {
  description = "Debian cloud image URL used to create the runner VM disk."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

variable "runner_vm_cloud_image_file_name" {
  description = "File name to use for the runner VM cloud image in Proxmox import storage."
  type        = string
  default     = "debian-12-genericcloud-amd64.qcow2"
}

variable "runner_vm_cloud_image_datastore_id" {
  description = "Proxmox datastore used to store the downloaded runner cloud image."
  type        = string
  default     = "local"
}

variable "runner_vm_datastore_id" {
  description = "Proxmox datastore for the runner VM disk and cloud-init disk."
  type        = string
  default     = "local-lvm"
}

variable "runner_vm_ipv4_address" {
  description = "Runner VM IPv4 address in CIDR notation, or dhcp."
  type        = string
  default     = "dhcp"
}

variable "runner_vm_ipv4_gateway" {
  description = "Runner VM IPv4 gateway. Leave empty when runner_vm_ipv4_address is dhcp."
  type        = string
  default     = ""
}

variable "kubernetes_vm_cloud_image_url" {
  description = "Debian 13 cloud image URL used to create Kubernetes VM disks."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

variable "kubernetes_vm_cloud_image_file_name" {
  description = "File name to use for the Kubernetes VM cloud image in Proxmox import storage."
  type        = string
  default     = "debian-13-genericcloud-amd64.qcow2"
}

variable "kubernetes_vm_cloud_image_datastore_id" {
  description = "Proxmox datastore used to store the downloaded Kubernetes cloud image."
  type        = string
  default     = "local"
}

variable "kubernetes_vm_datastore_id" {
  description = "Proxmox datastore for Kubernetes VM disks and cloud-init disks."
  type        = string
  default     = "local-lvm"
}

variable "kubernetes_vm_ipv4_addresses" {
  description = "Kubernetes VM IPv4 addresses in CIDR notation keyed by hostname, or dhcp."
  type        = map(string)
  default = {
    kubernetes-control = "dhcp"
    kubernetes-node1   = "dhcp"
    kubernetes-node2   = "dhcp"
    kubernetes-node3   = "dhcp"
  }
}

variable "kubernetes_vm_ipv4_gateway" {
  description = "Kubernetes VM IPv4 gateway. Leave empty when Kubernetes VM addresses are dhcp."
  type        = string
  default     = ""
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  description = "Primary Proxmox API endpoint URL"
  type        = string
  sensitive   = true
}

variable "proxmox2_endpoint" {
  description = "Secondary Proxmox API endpoint URL"
  type        = string
  sensitive   = true
}

variable "proxmox3_endpoint" {
  description = "Tertiary Proxmox API endpoint URL"
  type        = string
  sensitive   = true
}

variable "kubernetes_lxc_template_file_id" {
  description = "Debian 13 lxc template"
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}