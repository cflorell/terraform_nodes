resource "proxmox_virtual_environment_vm" "haosova" {
  acpi                                 = true
  bios                                 = "ovmf"
  boot_order                           = ["sata0"]
  delete_unreferenced_disks_on_destroy = true
  description                          = ""
  keyboard_layout                      = "sv"
  migrate                              = false
  name                                 = "haosova"
  node_name                            = "proxmox2"
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
  vm_id                                = 105

  network_device = [
    {
      bridge       = "vmbr0"
      disconnected = false
      enabled      = true
      firewall     = false
      mac_address  = "92:1A:27:3C:C7:CC"
      model        = "virtio"
      mtu          = 0
      queues       = 0
      rate_limit   = 0
      trunks       = ""
      vlan_id      = 0
    }
  ]

  agent {
    enabled = true
    timeout = "15m"
    trim    = false
    type    = "virtio"
  }

  cpu {
    cores      = 2
    flags      = []
    hotplugged = 0
    limit      = 0
    numa       = false
    sockets    = 1
    type       = "qemu64"
  }

  disk {
    aio               = "io_uring"
    backup            = true
    cache             = "none"
    datastore_id      = "local-lvm"
    discard           = "ignore"
    file_format       = "raw"
    interface         = "sata0"
    iothread          = false
    path_in_datastore = "vm-105-disk-1"
    queues            = 0
    replicate         = true
    size              = 32
    ssd               = false
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    pre_enrolled_keys = false
    type              = "2m"
  }

  memory {
    dedicated      = 4096
    floating       = 0
    keep_hugepages = false
    shared         = 0
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  usb {
    host = "10c4:ea60"
    usb3 = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
