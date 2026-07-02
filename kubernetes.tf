locals {
  kubernetes_vm_nodes = {
    "kubernetes-control" = {
      cores       = 2
      disk_size   = 32
      mac_address = "BC:24:11:8B:10:10"
      memory      = 4096
      vm_id       = 120
    }

    "kubernetes-node1" = {
      cores       = 2
      disk_size   = 32
      mac_address = "BC:24:11:8B:10:11"
      memory      = 4096
      vm_id       = 121
    }

    "kubernetes-node2" = {
      cores       = 2
      disk_size   = 32
      mac_address = "BC:24:11:8B:10:12"
      memory      = 4096
      vm_id       = 122
    }

    "kubernetes-node3" = {
      cores       = 2
      disk_size   = 32
      mac_address = "BC:24:11:8B:10:13"
      memory      = 4096
      vm_id       = 123
    }
  }

  kubernetes_vm_ipv4_addresses = {
    for name in keys(local.kubernetes_vm_nodes) : name => lookup(var.kubernetes_vm_ipv4_addresses, name, "dhcp")
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  for_each     = local.kubernetes_vm_nodes
  node_name    = "proxmox3"
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    data = templatefile("${path.module}/user-data.yaml", {
      hostname = each.key
      ssh_keys = var.vm_ssh_public_keys
    })
    file_name = "cloud-init-${each.key}.yaml"
  }
}

resource "proxmox_download_file" "kubernetes_cloud_image" {
  content_type = "import"
  datastore_id = var.kubernetes_vm_cloud_image_datastore_id
  file_name    = var.kubernetes_vm_cloud_image_file_name
  node_name    = "proxmox3"
  url          = var.kubernetes_vm_cloud_image_url
}

resource "proxmox_virtual_environment_vm" "kubernetes" {
  for_each = local.kubernetes_vm_nodes

  acpi                                 = true
  bios                                 = "ovmf"
  boot_order                           = ["scsi0"]
  delete_unreferenced_disks_on_destroy = true
  description                          = "Kubernetes node managed by Terraform"
  keyboard_layout                      = "sv"
  machine                              = "q35"
  migrate                              = false
  name                                 = each.key
  node_name                            = "proxmox3"
  on_boot                              = true
  protection                           = false
  purge_on_destroy                     = true
  reboot                               = false
  reboot_after_update                  = true
  scsi_hardware                        = "virtio-scsi-pci"
  started                              = true
  stop_on_destroy                      = false
  tablet_device                        = true
  tags                                 = ["kubernetes"]
  template                             = false
  vm_id                                = each.value.vm_id

  agent {
    enabled = true
    timeout = "15m"
    trim    = true
    type    = "virtio"

    wait_for_ip {
      ipv4 = local.kubernetes_vm_ipv4_addresses[each.key] == "dhcp"
    }
  }

  cpu {
    cores      = each.value.cores
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
    datastore_id = var.kubernetes_vm_datastore_id
    discard      = "on"
    file_format  = "raw"
    import_from  = proxmox_download_file.kubernetes_cloud_image.id
    interface    = "scsi0"
    iothread     = false
    queues       = 0
    replicate    = true
    size         = each.value.disk_size
    ssd          = false
  }

  efi_disk {
    datastore_id      = var.kubernetes_vm_datastore_id
    file_format       = "raw"
    pre_enrolled_keys = false
    type              = "2m"
  }

  initialization {
    datastore_id = var.kubernetes_vm_datastore_id

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data[each.key].id

    ip_config {
      ipv4 {
        address = local.kubernetes_vm_ipv4_addresses[each.key]
        gateway = local.kubernetes_vm_ipv4_addresses[each.key] == "dhcp" ? null : var.kubernetes_vm_ipv4_gateway
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
    dedicated      = each.value.memory
    floating       = 0
    keep_hugepages = false
    shared         = 0
  }

  network_device {
    bridge       = "vmbr0"
    disconnected = false
    enabled      = true
    firewall     = false
    mac_address  = each.value.mac_address
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

    prevent_destroy = false
  }
}
