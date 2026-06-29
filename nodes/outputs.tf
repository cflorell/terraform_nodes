locals {
  ansible_node_hosts = {
    docker = {
      ansible_host = proxmox_virtual_environment_container.docker.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    authentik = {
      ansible_host = proxmox_virtual_environment_container.authentik.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    immich = {
      ansible_host = proxmox_virtual_environment_container.immich.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    "prometheus-grafana" = {
      ansible_host = proxmox_virtual_environment_container.prometheus_grafana.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    media = {
      ansible_host = proxmox_virtual_environment_container.media.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    torrent = {
      ansible_host = proxmox_virtual_environment_container.torrent.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    media2 = {
      ansible_host = proxmox_virtual_environment_container.media2.ipv4["eth0"]
      ansible_user = "root"
      ansible_port = 22
    }

    runner = {
      ansible_host = var.runner_vm_ipv4_address != "dhcp" ? split("/", var.runner_vm_ipv4_address)[0] : try(
        flatten([
          for idx, mac_address in proxmox_virtual_environment_vm.runner.mac_addresses :
          proxmox_virtual_environment_vm.runner.ipv4_addresses[idx]
          if lower(mac_address) == lower(local.runner_mac_address)
        ])[0], 
        "pending-dhcp-lease" # Fallback string if the list is empty
      )
      ansible_user = "root"
      ansible_port = 22
    }
  }
}

output "ansible_inventory" {
  description = "Ansible inventory for Terraform-managed service nodes."
  value = {
    all = {
      children = {
        nodes = {
          vars = {
            ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
          }
          hosts = local.ansible_node_hosts
        }
      }
    }
  }
}
