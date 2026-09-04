terraform {
  required_version = ">= 1.6.0"

  # GitLab-managed remote state; configure with `terraform init -backend-config=backend.hcl`
  # (see README "Remote state") or TF_HTTP_* environment variables in CI.
  backend "http" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.112"
    }
  }
}

# insecure = false: Terraform verifies each host's Let's Encrypt cert (issued by
# ansible_nodes via PVE-native ACME; endpoints are the cert FQDNs). See README
# "Provider TLS" to revert a host to self-signed.
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = false
}

provider "proxmox" {
  alias    = "proxmox2"
  endpoint = var.proxmox2_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = false
}

provider "proxmox" {
  alias    = "proxmox3"
  endpoint = var.proxmox3_endpoint
  username = "root@pam"
  password = var.proxmox_password
  insecure = false
}
