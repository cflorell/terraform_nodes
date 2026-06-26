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
vm_password       = "change-me"
proxmox_token     = "change-me"
proxmox_endpoint  = "https://proxmox.example.com:8006/"
proxmox2_endpoint = "https://proxmox2.example.com:8006/"
proxmox3_endpoint = "https://proxmox3.example.com:8006/"
```

Then link them into this checkout:

```bash
export HOMELAB_SECRETS_DIR=/path/to/private/secrets
scripts/link-private-files.sh --adopt
scripts/link-private-files.sh --check
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
