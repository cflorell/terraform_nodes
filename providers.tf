terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}

provider "proxmox" {
  alias    = "proxmox2"
  endpoint = var.proxmox2_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}

provider "proxmox" {
  alias    = "proxmox3"
  endpoint = var.proxmox3_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}
