# Sandbox Environment

Three-VPC IRE topology (landing zone, core recovery, protected data)
connected via Transit Gateway.

> **Deviation from the IRE HLD:** the production design has no Internet
> Gateway or NAT anywhere (access is via Client VPN only). This sandbox
> intentionally includes an IGW + public subnets in the landing zone for
> low-cost testing. Remove `public_subnets` to match the HLD.

## Usage

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/<change-name>

cd terraform/environments/sandbox

cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl

# Update only local values.

terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

Each collaborator maintains their own `terraform.tfvars` and `backend.hcl`.
Both files are local configuration and must not be committed. Update the
committed example files only when the root module's supported interface
changes.

AWS credentials must come from an approved authentication mechanism. Never
place credentials in Terraform variable or backend files. CI/CD must supply
its own backend and variable configuration rather than using a developer's
local files.

Before committing, run `git status` and confirm that the branch contains no
workstation-specific paths, credentials, state, plans, logs, or local backend
configuration.
