resource "proxmox_virtual_environment_container" "llm" {
  description           = "LLM front end (Open WebUI + SearXNG) managed by Terraform\n"
  environment_variables = {}
  node_name             = "proxmox"
  protection            = false
  start_on_boot         = true
  started               = true
  tags                  = []
  template              = false
  unprivileged          = false
  vm_id                 = 109

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = 4
    limit        = 0
  }

  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 32
  }

  # nesting is what lets Docker run inside the container; no NFS mount is
  # needed since nothing here reads from the storage shares.
  features {
    fuse    = true
    keyctl  = false
    mknod   = false
    mount   = []
    nesting = true
  }

  initialization {
    hostname = "llm"

    ip_config {
      ipv4 {
        address = "dhcp"
        gateway = ""
      }

      ipv6 {
        address = "auto"
        gateway = ""
      }
    }

    # The older containers in this project were imported after being created by
    # hand and carry no user_account block. This one is created by Terraform, so
    # the root credentials Ansible connects with are set here.
    user_account {
      keys     = var.vm_ssh_public_keys
      password = var.vm_password
    }
  }

  memory {
    dedicated = 4096
    swap      = 1024
  }

  network_interface {
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = "BC:24:11:9E:4D:09"
    mtu          = 0
    name         = "eth0"
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.llm_lxc_template_file_id
    type             = "debian"
  }

  lifecycle {
    # The provider does not round-trip these imported/default fields cleanly.
    ignore_changes = [
      timeout_clone,
      timeout_create,
      timeout_delete,
      timeout_start,
      timeout_update,
      vm_id,
    ]

    prevent_destroy = true
  }
}
