locals {
  ansible_service_node_hosts = {
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

    llm = {
      ansible_host = proxmox_virtual_environment_container.llm.ipv4["eth0"]
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

  ansible_kubernetes_control_hosts = {
    "kubernetes-control" = {
      ansible_host = local.kubernetes_vm_ipv4_addresses["kubernetes-control"] != "dhcp" ? split("/", local.kubernetes_vm_ipv4_addresses["kubernetes-control"])[0] : try(
        flatten([
          for idx, mac_address in proxmox_virtual_environment_vm.kubernetes["kubernetes-control"].mac_addresses :
          proxmox_virtual_environment_vm.kubernetes["kubernetes-control"].ipv4_addresses[idx]
          if lower(mac_address) == lower(local.kubernetes_vm_nodes["kubernetes-control"].mac_address)
        ])[0],
        "pending-dhcp-lease"
      )
      ansible_user = "root"
      ansible_port = 22
    }
  }

  ansible_kubernetes_worker_hosts = {
    for name in ["kubernetes-node1", "kubernetes-node2", "kubernetes-node3"] : name => {
      ansible_host = local.kubernetes_vm_ipv4_addresses[name] != "dhcp" ? split("/", local.kubernetes_vm_ipv4_addresses[name])[0] : try(
        flatten([
          for idx, mac_address in proxmox_virtual_environment_vm.kubernetes[name].mac_addresses :
          proxmox_virtual_environment_vm.kubernetes[name].ipv4_addresses[idx]
          if lower(mac_address) == lower(local.kubernetes_vm_nodes[name].mac_address)
        ])[0],
        "pending-dhcp-lease"
      )
      ansible_user = "root"
      ansible_port = 22
    }
  }

  ansible_node_hosts = merge(
    local.ansible_service_node_hosts,
    local.ansible_kubernetes_control_hosts,
    local.ansible_kubernetes_worker_hosts,
  )
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

        kubernetes = {
          children = {
            kubernetes_control = {
              hosts = local.ansible_kubernetes_control_hosts
            }

            kubernetes_workers = {
              hosts = local.ansible_kubernetes_worker_hosts
            }
          }
        }
      }
    }
  }
}
