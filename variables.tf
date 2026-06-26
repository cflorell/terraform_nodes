variable "vm_password" {
  description = "Password for the user"
  type        = string
  sensitive   = true
}

variable "proxmox_token" {
  description = "Proxmox api token"
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
