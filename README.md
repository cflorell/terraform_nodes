# Terraform Nodes

Terraform configuration for a Proxmox-managed homelab's nodes.

## Project roots

The repository holds two independent Terraform projects, each with its own
state, provider set, tfvars and backend configuration:

| Directory    | State name  | Manages                                       |
| ------------ | ----------- | --------------------------------------------- |
| `infra/`     | `homelab`   | Proxmox VMs and LXCs via `bpg/proxmox`        |
| `authentik/` | `authentik` | Authentik objects via `goauthentik/authentik` |

`infra/` keeps one `.tf` per logical service or node group. `authentik/`
holds groups, proxy and OIDC providers, applications and policy bindings.

Most containers in `infra/` were created by hand and imported afterwards,
which is why they carry an empty `template_file_id` and no `user_account`
block: the provider only refreshes what already exists. `llm.tf` is created by
Terraform outright, so it names an LXC template
(`var.llm_lxc_template_file_id`) and sets the root credentials Ansible
connects with. That template has to exist on the node the container is created
on already; download it there with
`pveam update && pveam download local <template>`. Containers take their
address over DHCP, so a new one also needs a reservation for its declared MAC
address on the OPNsense side before Ansible can reach it at a fixed IP.

They are separate because they operate at different layers. `infra/`
provisions machines; `authentik/` configures a service that Ansible has
already deployed onto one of them. Keeping the state and CI jobs apart means
an unreachable Authentik cannot block an infrastructure plan, and an Authentik
object change never triggers one.

Run Terraform from inside the relevant directory:

```bash
cd infra      # or: cd authentik
terraform init -backend-config=backend.hcl
terraform plan
```

Ordering across the layers is `infra/` apply, then Ansible deploys Authentik,
then `authentik/` apply. The `authentik/` project needs its target reachable
at `var.authentik_url` and an API token, so it cannot run before that.

## Setup

Terraform reads plaintext `terraform.tfvars` and `backend.hcl` at runtime, but
neither is kept in plaintext at rest. Both live in a separate private repo with
a mirrored project directory, encrypted with SOPS/age as
`terraform.tfvars.sops`/`backend.hcl.sops` (whole-file binary encryption, since
neither format is YAML/JSON). The `.sops` files are linked into this checkout
and decrypted locally to the gitignored plaintext files (see below); the
plaintext is never committed.

Without access to the private repo, seed a local `terraform.tfvars` from the
committed template instead and fill it in by hand:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
cp authentik/terraform.tfvars.example authentik/terraform.tfvars
```

The private repo layout is:

```text
secrets/
  terraform_nodes/
    terraform.tfvars.sops            # infra/, flat path predating the split
    backend.hcl.sops                 # infra/, flat path predating the split
    authentik/terraform.tfvars.sops
    authentik/backend.hcl.sops
```

Sources are looked up at the path matching their location in this repo
(`infra/terraform.tfvars.sops` and so on). The two flat paths above predate
the split into project roots and are still accepted for `infra/`, so the
secrets repo needs no reorganization. Moving them under `infra/` there works
too, and the scripts prefer that layout when it exists.

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
sops edit --input-type binary --output-type binary infra/terraform.tfvars.sops
sops edit --input-type binary --output-type binary infra/backend.hcl.sops
scripts/decrypt-private-files.sh
```

Both scripts operate on every project root at once and are run from the
repository root, not from inside `infra/` or `authentik/`. Files for a project
whose secrets do not exist yet are reported and skipped rather than failing
the run.

## Provider TLS (Proxmox `insecure`)

The `proxmox` provider blocks in `infra/providers.tf` set `insecure = false` and use
FQDN endpoints (`proxmox<N>.<domain>:8006`), so Terraform verifies each
hypervisor's Let's Encrypt certificate. Those certs are issued and renewed by
`ansible_nodes` (Proxmox-native ACME over Porkbun DNS-01), and the FQDNs resolve
via OPNsense Unbound overrides so both local runs and the in-cluster CI job can
reach them by name.

How the certs are issued, the DNS requirement, and how to
enable a new host or **disable PKI and revert to self-signed**, lives in the
`ansible_nodes` README ("PKI / TLS certificates").  In short,
to make Terraform tolerate a self-signed cert again on a host: set its block back
to `insecure = true` (and optionally revert its `*_endpoint` in `terraform.tfvars`
to an IP), then `terraform apply`.

## Remote state (GitLab-managed)

State is stored in GitLab's managed Terraform state (project sidebar:
**Operate → Terraform states**), not in the repository. Both project roots use
the same GitLab project and are told apart by state name, `homelab` for
`infra/` and `authentik` for `authentik/`, so a second project costs one
backend setting rather than a second repository.

### One-time migration from local state

```bash
cd infra
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

`terraform init -backend-config=backend.hcl` once per fresh checkout, from
inside each project root that is in use; plan and apply work as before.
`backend.hcl` contains an access token, so it's handled the same way as
`terraform.tfvars`, linked in from the private secrets repo as SOPS/age-encrypted
`backend.hcl.sops` and decrypted locally with `scripts/decrypt-private-files.sh`.

### CI (merge request plan, manual apply)

Each project root has its own job set, gated on changes under its own
directory, so the two never trigger each other:

- `terraform_fmt`, one repo-wide formatting check, on shared runners.
- `terraform_validate_infra` / `terraform_validate_authentik`, validate
  without a backend, on shared runners.
- `terraform_plan_infra` / `terraform_plan_authentik`, full plan on every MR,
  on the self-hosted runner; the MR widget shows the resource change counts.
- `terraform_apply_infra` / `terraform_apply_authentik`, manual jobs on `main`.

The `authentik` plan and apply jobs additionally require the project variable
`AUTHENTIK_TF_ENABLED` to be `"true"`. They configure a running service rather
than provisioning one, so they need Authentik reachable at `var.authentik_url`
and its secrets present in the private repo; both arrive with the Authentik
Terraform configuration itself.

The plan and apply jobs clone the private secrets repo with the job token,
link the `.sops` files in via `scripts/link-private-files.sh`, and decrypt
them with `scripts/decrypt-private-files.sh`. Both scripts run from the
repository root and cover every project. Required setup in GitLab:

- **Settings → CI/CD → Variables**: `SOPS_AGE_KEY` - type **Variable**,
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
as `*.tfvars`, `*.tfvars.sops`, `backend.hcl`, `backend.hcl.sops`, plans, crash
logs, `.terraform/`, private helper backups, and suspicious symlinks. It also
scans staged content for obvious literal secret assignments. (`*.tfstate` is
kept out of commits by `.gitignore`.)

`pre-push` runs the local sanity checks:

- Shows `git status --short --ignored`.
- Verifies each project root's `terraform.tfvars.sops` and `backend.hcl.sops`
  are linked from the private secrets repository. (State is GitLab-managed
  remote, not a linked local file.) A project whose secrets do not exist yet is
  skipped rather than failing the check.
- Fails if Terraform runtime/private files are tracked.
- Runs `terraform fmt -check` over git-tracked `*.tf`/`*.tfvars` files (a
  recursive check would also flag the gitignored plaintext `terraform.tfvars`
  decrypted from `terraform.tfvars.sops`, which SOPS leaves unformatted).

If the private secrets repository is not at `../private/secrets`, set:

```bash
export HOMELAB_SECRETS_DIR="$HOME/git_private/homelab-secrets"
```

For a one-off bypass:

```bash
SKIP_PRIVATE_LINK_CHECK=1 git push
SKIP_TERRAFORM_FMT_CHECK=1 git push
```
