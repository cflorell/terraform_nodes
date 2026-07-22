# Terraform Nodes

Terraform configuration for a Proxmox-managed homelab's nodes.

## Setup

Copy or symlink private runtime files before running Terraform:

```bash
cp terraform.tfvars.example terraform.tfvars
```

For the private-repo workflow, store real private files in a separate private repo with a mirrored project directory. `terraform.tfvars` and `backend.hcl` are
kept there as SOPS/age-encrypted `terraform.tfvars.sops`/`backend.hcl.sops`
(whole-file binary encryption, since neither format is YAML/JSON) rather than
in plaintext:

```text
secrets/
  terraform_nodes/
    terraform.tfvars.sops
    backend.hcl.sops
```

`terraform.tfvars` contains runtime secrets and private topology values:

```hcl
vm_password                            = "change-me"
vm_ssh_public_keys                     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIrunnerexample"]
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

`vm_ssh_public_keys` is shared by every `proxmox_virtual_environment_vm`
resource's cloud-init (`runner.tf`'s `user_account.keys`, `kubernetes.tf`'s
`user-data.yaml` template) - it's meant to hold every key that should have
root access from first boot, not just a personal one.

Public keys are fetched with
```bash
ssh root@<runner-vm> cat /home/gitlab-runner/.ssh/id_ed25519.pub
ssh root@<kube-control> cat /etc/kubernetes/gitlab-runner-k8s-ssh/id_ed25519.pub
```

The runner and Kubernetes VMs are created from Debian cloud images downloaded
into Proxmox import storage. The images must include cloud-init. Terraform
enables the QEMU guest agent and uses it to export DHCP addresses for Ansible.
If an image does not include `qemu-guest-agent` before Ansible runs, set the
matching static IPv4 variables so Terraform can export Ansible addresses without
waiting for the guest agent on first boot.

Then link them into this checkout and decrypt working `terraform.tfvars`/`backend.hcl` files:

```bash
export HOMELAB_SECRETS_DIR=/path/to/private/secrets
scripts/link-private-files.sh --adopt
scripts/link-private-files.sh --check
scripts/decrypt-private-files.sh
```

`scripts/decrypt-private-files.sh` requires `sops`/`age` installed and the
personal age private key at `~/.config/sops/age/keys.txt` (its public half is
a recipient in `private/secrets/.sops.yaml`). It regenerates the gitignored
`terraform.tfvars` and `backend.hcl` from their `.sops` counterparts - never
edit either directly, they will be overwritten. To edit a secret itself:

```bash
sops edit --input-type binary --output-type binary terraform.tfvars.sops
sops edit --input-type binary --output-type binary backend.hcl.sops
scripts/decrypt-private-files.sh
```

## Remote state (GitLab-managed)

State is stored in GitLab's managed Terraform state (project sidebar:
**Operate → Terraform states**), not in the repository. Even though the
repository is public, state is only readable by project members (Developer
role and up) over an authenticated API — it is never exposed on the public
project pages. GitLab versions the state and provides locking.

### One-time migration from local state

```bash
cp backend.hcl.example backend.hcl   # gitignored; fill in project ID, username, PAT (api scope)
terraform init -migrate-state -backend-config=backend.hcl
```

Answer `yes` when Terraform offers to copy the existing local state. Afterwards
the local `terraform.tfstate` symlink is obsolete; keep the file in the private
secrets repo as a backup or delete it once the remote state is verified with
`terraform plan` (expect no changes). Once `backend.hcl` is filled in, adopt it
into the private secrets repo as `backend.hcl.sops` so it's encrypted at rest
and linked in like `terraform.tfvars`:

```bash
scripts/link-private-files.sh --adopt
```

### Day-to-day local use

`terraform init -backend-config=backend.hcl` once per fresh checkout; plan and
apply work as before. `backend.hcl` contains an access token, so it's handled
the same way as `terraform.tfvars` — linked in from the private secrets repo
as SOPS/age-encrypted `backend.hcl.sops` and decrypted locally with
`scripts/decrypt-private-files.sh`.

### CI (merge request plan, manual apply)

- `terraform_validate` — fmt + validate on every MR, on shared runners.
- `terraform_plan` — full plan on every MR, on the self-hosted runner (it can
  reach the Proxmox endpoints); the MR widget shows the resource change counts.
- `terraform_apply` — manual job on `main`.

`terraform_plan`/`terraform_apply` clone the private secrets repo with the
job token, link `terraform.tfvars.sops` in via `scripts/link-private-files.sh`,
and decrypt it with `scripts/decrypt-private-files.sh`. Required setup in GitLab:

- **Settings → CI/CD → Variables**: `SOPS_AGE_KEY` — type **Variable**,
  masked, the private half of an age keypair whose public half is a recipient
  in `private/secrets/.sops.yaml`. Do not mark it protected, or MR pipelines
  will not receive it. (Skip this if it's already set at the `cf_homelab`
  group level for the other repos.)
- The `secrets` project's **Settings → CI/CD → Job token permissions** must
  allow `terraform_nodes` to access it with the job token (same as
  `ansible_nodes` already does).

The self-hosted runner needs `terraform`, `jq`, `git`, and `sops` installed.
Because the
project is public, restrict pipeline and job-log visibility to project members
(**Settings → CI/CD → General pipelines**), since plan output prints resource
details.

## Git hooks

Install the project hooks in this checkout:

```bash
git config core.hooksPath .githooks
```

The hooks are local to each clone. They are versioned in this repository, but
Git will not use them until `core.hooksPath` is configured.

`pre-commit` blocks accidental commits of Terraform runtime/private files such
as `*.tfvars`, `*.tfvars.sops`, `backend.hcl`, `backend.hcl.sops`, `*.tfstate`,
plans, crash logs, `.terraform/`, private helper backups, and suspicious
symlinks. It also scans staged content for obvious literal secret assignments.

`pre-push` runs the local sanity checks:

- Shows `git status --short --ignored`.
- Verifies `terraform.tfvars.sops`, `backend.hcl.sops`, and `terraform.tfstate`
  are linked from the private secrets repository.
- Fails if Terraform runtime/private files are tracked.
- Runs `terraform fmt -check -recursive`.

If the private secrets repository is not at `../private/secrets`, set:

```bash
export HOMELAB_SECRETS_DIR="$HOME/git_private/homelab-secrets"
```

For a one-off bypass:

```bash
SKIP_PRIVATE_LINK_CHECK=1 git push
SKIP_TERRAFORM_FMT_CHECK=1 git push
```
