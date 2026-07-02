resource "proxmox_virtual_environment_container" "torrent" {
  description           = " USB passthrough\n"
  environment_variables = {}
  node_name             = "proxmox"
  protection            = false
  start_on_boot         = true
  started               = true
  tags                  = []
  template              = false
  unprivileged          = false
  vm_id                 = 106

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = 8
    limit        = 0
  }

  device_passthrough {
    deny_write = false
    gid        = 0
    mode       = "0660"
    path       = "/dev/net/tun"
    uid        = 0
  }

  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 16
  }

  features {
    fuse    = true
    keyctl  = false
    mknod   = false
    mount   = ["nfs"]
    nesting = true
  }

  initialization {
    hostname = "torrent"

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
    swap      = 0
  }

  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/Storage1"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = ""
    volume        = "/mnt/Storage1"
  }

  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/Storage2"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = ""
    volume        = "/mnt/Storage2"
  }

  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/Storage3"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = ""
    volume        = "/mnt/Storage3"
  }

  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/Storage4"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = ""
    volume        = "/mnt/Storage4"
  }

  network_interface {
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = "BC:24:11:2C:AA:F8"
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
      description,
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
