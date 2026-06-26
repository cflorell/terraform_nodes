module "nodes" {
  source = "./nodes"

  providers = {
    proxmox = proxmox
  }
}
