resource "proxmox_virtual_environment_container" "media2" {
  description           = ""
  environment_variables = {}
  node_name             = "proxmox2"
  protection            = false
  start_on_boot         = true
  started               = true
  tags                  = []
  template              = false
  unprivileged          = false
  vm_id                 = 107

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = 2
    limit        = 0
  }

  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 24
  }

  features {
    fuse    = true
    keyctl  = false
    mknod   = false
    mount   = ["nfs"]
    nesting = true
  }

  initialization {
    hostname = "media2"

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
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  network_interface {
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = "BC:24:11:73:59:94"
    mtu          = 0
    name         = "eth0"
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = ""
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
