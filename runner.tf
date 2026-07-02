locals {
  runner_mac_address = "BC:24:11:52:34:A8"
}

resource "proxmox_download_file" "runner_cloud_image" {
  content_type = "import"
  datastore_id = var.runner_vm_cloud_image_datastore_id
  file_name    = var.runner_vm_cloud_image_file_name
  node_name    = "proxmox"
  url          = var.runner_vm_cloud_image_url
}

resource "proxmox_virtual_environment_vm" "runner" {
  acpi                                 = true
  bios                                 = "ovmf"
  boot_order                           = ["scsi0"]
  delete_unreferenced_disks_on_destroy = true
  description                          = "GitLab shell runner with Vagrant/libvirt support"
  keyboard_layout                      = "sv"
  machine                              = "q35"
  migrate                              = false
  name                                 = "runner"
  node_name                            = "proxmox"
  on_boot                              = true
  protection                           = false
  purge_on_destroy                     = true
  reboot                               = false
  reboot_after_update                  = true
  scsi_hardware                        = "virtio-scsi-pci"
  started                              = true
  stop_on_destroy                      = false
  tablet_device                        = true
  tags                                 = []
  template                             = false
  vm_id                                = 108

  agent {
    enabled = true
    timeout = "15m"
    trim    = true
    type    = "virtio"
    wait_for_ip {
      # Use ONE of these depending on your provider version:
      # If using older provider: enabled = var.runner_vm_ipv4_address == "dhcp"     
      ipv4 = var.runner_vm_ipv4_address == "dhcp"
    }
  }


  cpu {
    cores      = 4
    flags      = []
    hotplugged = 0
    limit      = 0
    numa       = false
    sockets    = 1
    type       = "host"
  }

  disk {
    aio          = "io_uring"
    backup       = true
    cache        = "none"
    datastore_id = var.runner_vm_datastore_id
    discard      = "on"
    file_format  = "raw"
    import_from  = proxmox_download_file.runner_cloud_image.id
    interface    = "scsi0"
    iothread     = false
    queues       = 0
    replicate    = true
    size         = 64
    ssd          = false
  }

  efi_disk {
    datastore_id      = var.runner_vm_datastore_id
    file_format       = "raw"
    pre_enrolled_keys = false
    type              = "2m"
  }

  initialization {
    datastore_id = var.runner_vm_datastore_id

    ip_config {
      ipv4 {
        address = var.runner_vm_ipv4_address
        gateway = var.runner_vm_ipv4_address == "dhcp" ? null : var.runner_vm_ipv4_gateway
      }

      ipv6 {
        address = "auto"
      }
    }


    user_account {
      keys     = var.vm_ssh_public_keys
      password = var.vm_password
      username = "root"
    }
  }

  memory {
    dedicated      = 8192
    floating       = 0
    keep_hugepages = false
    shared         = 0
  }

  network_device {
    bridge       = "vmbr0"
    disconnected = false
    enabled      = true
    firewall     = false
    mac_address  = local.runner_mac_address
    model        = "virtio"
    mtu          = 0
    queues       = 0
    rate_limit   = 0
    trunks       = ""
    vlan_id      = 0
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  lifecycle {
    # The provider does not round-trip these imported/default fields cleanly.
    ignore_changes = [
      timeout_clone,
      timeout_create,
      timeout_migrate,
      timeout_reboot,
      timeout_shutdown_vm,
      timeout_start_vm,
      timeout_stop_vm,
      vm_id,
    ]

    prevent_destroy = true
  }
}
