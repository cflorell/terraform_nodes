terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "terraform@pve!terraform-token=${var.proxmox_token}"
  insecure  = true
}

provider "proxmox" {
  alias     = "proxmox2"
  endpoint  = var.proxmox2_endpoint
  api_token = "terraform@pve!terraform-token=${var.proxmox_token}"
  insecure  = true
}

provider "proxmox" {
  alias     = "proxmox3"
  endpoint  = var.proxmox3_endpoint
  api_token = "terraform@pve!terraform-token=${var.proxmox_token}"
  insecure  = true
}
