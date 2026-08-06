# Terraform Module Tests

This directory contains independent Terraform root modules used to validate the
reusable modules in `terraform/modules`.

A module test answers a narrow question: does the documented module interface
format, initialize, validate, plan, apply when approved, become idempotent, and
destroy cleanly with the minimum required supporting resources?

## Relationship to Sandbox

`terraform/environments/sandbox` is an integration root. It currently composes:

- Recovery Access VPC;
- Core Recovery VPC;
- Protected Data VPC;
- centralized Inspection VPC;
- Transit Gateway segmentation;
- centralized Network Firewall;
- encrypted firewall logging;
- Client VPN;
- security groups and EC2;
- KMS and AWS Backup.

Module tests do not reproduce that architecture. They isolate individual module
contracts and lifecycle behavior.

## Available test roots

| Directory | Primary module or composition |
|---|---|
| `vpc` | VPC |
| `transit-gateway` | Transit Gateway |
| `ec2` | EC2 |
| `security-group` | Security group and standalone rules |
| `client-vpn` | Client VPN |
| `kms` | KMS |
| `backup-vault` | AWS Backup module composition |
| `managed-microsoft-ad` | Managed Microsoft AD |
| `network-firewall-rule-group` | Network Firewall rule groups |
| `network-firewall-policy` | Network Firewall policy |
| `network-firewall` | VPC-attached Network Firewall |
| `network-firewall-routing` | VPC and TGW routing resources |
| `network-firewall-logging` | Firewall logging destinations |
| `network-firewall-tls-inspection` | TLS inspection configuration |

`test-logs` is an output directory for test-run logs, not a Terraform test root.

## Validation-only workflow

Validation does not require an AWS-backed state:

```bash
cd terraform/environments/module-tests/<name>

terraform init -backend=false -input=false
terraform fmt -check -recursive
terraform validate
```

## Approved AWS-backed lifecycle test

Create local configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Use a unique backend key for every test root:

```bash
terraform init \
  -input=false \
  -reconfigure \
  -backend-config=backend.hcl

terraform plan \
  -input=false \
  -var-file=terraform.tfvars \
  -out=tfplan

terraform show tfplan
terraform apply -input=false tfplan
rm -f tfplan
```

Check idempotency:

```bash
terraform plan \
  -input=false \
  -var-file=terraform.tfvars \
  -detailed-exitcode

echo $?
```

Exit code `0` means no change, `1` means error, and `2` means changes detected.

Destroy through a reviewed saved plan:

```bash
terraform plan \
  -destroy \
  -input=false \
  -var-file=terraform.tfvars \
  -out=tfplan

terraform show tfplan
terraform apply -input=false tfplan
rm -f tfplan
terraform state list
```

## Cost and safety

Network Firewall, Transit Gateway, Client VPN, Managed Microsoft AD, KMS, and
backup resources can incur cost or have delayed deletion behavior. Run apply
only in an approved account and destroy immediately after lifecycle validation.

Never commit:

- `terraform.tfvars`;
- `backend.hcl`;
- state;
- saved plans;
- logs;
- credentials;
- certificates or private keys.

## Design principles

- Each test root is independent.
- Supporting resources are the smallest practical dependency set.
- VPC routing is not hidden in the reusable VPC module.
- Logical map keys are stable identities.
- Backend state keys are unique per test.
- Enterprise tags use the same `org_*` conventions as Sandbox.
