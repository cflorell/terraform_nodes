# Terraform Nodes

Terraform configuration for my Proxmox-managed homelab nodes.

## Setup

Copy or symlink private runtime files before running Terraform:

```bash
cp terraform.tfvars.example terraform.tfvars
```

For the private-repo workflow, store real private files in a separate private repo with a mirrored project directory:

```text
secrets/
  terraform_nodes/
    terraform.tfvars
    terraform.tfstate
```

`terraform.tfvars` contains runtime secrets and private topology values:

```hcl
vm_password                            = "change-me"
vm_ssh_public_keys                     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample"]
runner_vm_cloud_image_url              = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
runner_vm_cloud_image_file_name        = "debian-12-genericcloud-amd64.qcow2"
runner_vm_cloud_image_datastore_id     = "local"
runner_vm_datastore_id                 = "local-lvm"
runner_vm_ipv4_address                 = "dhcp"
runner_vm_ipv4_gateway                 = ""
kubernetes_vm_cloud_image_url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
kubernetes_vm_cloud_image_file_name    = "debian-13-genericcloud-amd64.qcow2"
kubernetes_vm_cloud_image_datastore_id = "local"
kubernetes_vm_datastore_id             = "local-lvm"
kubernetes_vm_ipv4_addresses = {
  kubernetes-control = "dhcp"
  kubernetes-node1   = "dhcp"
  kubernetes-node2   = "dhcp"
  kubernetes-node3   = "dhcp"
}
kubernetes_vm_ipv4_gateway = ""
proxmox_password           = "change-me"
proxmox_endpoint           = "https://proxmox.example.com:8006/"
proxmox2_endpoint          = "https://proxmox2.example.com:8006/"
proxmox3_endpoint          = "https://proxmox3.example.com:8006/"
```

The runner and Kubernetes VMs are created from Debian cloud images downloaded
into Proxmox import storage. The images must include cloud-init. Terraform
enables the QEMU guest agent and uses it to export DHCP addresses for Ansible.
If an image does not include `qemu-guest-agent` before Ansible runs, set the
matching static IPv4 variables so Terraform can export Ansible addresses without
waiting for the guest agent on first boot.

Then link them into this checkout:

```bash
export HOMELAB_SECRETS_DIR=/path/to/private/secrets
scripts/link-private-files.sh --adopt
scripts/link-private-files.sh --check
```

Run Terraform from the repository root:

```bash
terraform init
terraform plan
```

## Git hooks

Install the project hooks in this checkout:

```bash
git config core.hooksPath .githooks
```

The hooks are local to your clone. They are versioned in this repository, but
Git will not use them until `core.hooksPath` is configured.

`pre-commit` blocks accidental commits of Terraform runtime/private files such
as `*.tfvars`, `*.tfstate`, plans, crash logs, `.terraform/`, private helper
backups, and suspicious symlinks. It also scans staged content for obvious
literal secret assignments.

`pre-push` runs the local sanity checks:

- Shows `git status --short --ignored`.
- Verifies `terraform.tfvars` and `terraform.tfstate` are linked from the
  private secrets repository.
- Fails if Terraform runtime/private files are tracked.
- Runs `terraform fmt -check -recursive`.

If your private secrets repository is not at `../private/secrets`, set:

```bash
export HOMELAB_SECRETS_DIR="$HOME/git_private/homelab-secrets"
```

For a one-off bypass:

```bash
SKIP_PRIVATE_LINK_CHECK=1 git push
SKIP_TERRAFORM_FMT_CHECK=1 git push
```
