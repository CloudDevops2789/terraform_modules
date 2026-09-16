# Persistent Resources Stack

This Terraform root owns IRE resources whose lifecycle intentionally outlives
the Platform, Identity, Remote Access, and Recovery stacks.

It is called `persistent` because lifecycle is the shared characteristic. It is
not an account foundation or networking foundation stack.

## Ownership

When enabled, this stack can manage:

- a standard AWS Backup vault;
- a logically air-gapped AWS Backup vault; and
- a customer-managed KMS key for Network Firewall CloudWatch Logs encryption.

It does not own:

- VPCs, subnets, Transit Gateway, routing, or security groups;
- AWS Network Firewall;
- AWS Managed Microsoft AD;
- Client VPN;
- backup plans, selections, or recovery compute.

## Repository layout

```text
terraform/stacks/persistent/
├── backend.tf      # Backend declaration; runtime backend values come from AAP
├── provider.tf     # AWS Region and provider-level default tags
├── versions.tf     # Terraform and provider requirements
├── variables.tf    # Typed stack inputs and validation
├── locals.tf       # Derived names and organization tags
├── main.tf         # Persistent resource composition
├── outputs.tf      # Supported cross-stack contract
└── README.md       # Ownership, reference flow, and troubleshooting
```

Terraform loads every `*.tf` file in this directory together as one root module.

`main.tf` does not call `variables.tf`, `locals.tf`, `provider.tf`, or
`outputs.tf`. Terraform filenames are primarily for human organization.
References such as `var.*`, `local.*`, `module.*`, and `data.*` establish the
dependency graph.

## How Terraform references resolve

### Variable references

When code contains:

```hcl
var.name_prefix
```

look for the matching declaration in `variables.tf`:

```hcl
variable "name_prefix" {
  ...
}
```

The declaration defines the type, validation, default behavior, and description.
The actual value may come from an approved tfvars file or an approved AAP
runtime binding.

For this stack, Git-controlled configuration is supplied from:

```text
terraform/environments/<environment>/config/common-tags.tfvars
terraform/environments/<environment>/config/persistent.tfvars
```

AAP explicitly passes those files to Terraform. Terraform does not
automatically discover tfvars files stored in that environment config
directory.

### Local references

When code contains:

```hcl
local.standard_backup_vault_name
```

look in `locals.tf`.

For example:

```text
var.name_prefix
    |
    v
locals.tf
    |
    v
local.standard_backup_vault_name
    |
    v
main.tf
    |
    v
module.backup_standard_vault
```

Locals derive reusable values from variables or other expressions. They do not
represent separate resources.

### Module references

When code contains:

```hcl
module.backup_standard_vault
```

look for the matching module block in `main.tf`:

```hcl
module "backup_standard_vault" {
  source = "../../modules/backup-standard-vault"
  ...
}
```

The `source` value identifies the reusable child module implementing that
capability.

For example:

```text
main.tf
    |
    v
module "backup_standard_vault"
    |
    v
terraform/modules/backup-standard-vault/
    |
    v
AWS Backup vault resource
```

A reference such as:

```hcl
module.backup_standard_vault[0].name
```

means that the Persistent root is reading the `name` output exported by the
child module.

The full flow is:

```text
main.tf module block
    |
    v
terraform/modules/backup-standard-vault
    |
    v
child module output "name"
    |
    v
module.backup_standard_vault[0].name
    |
    v
Persistent outputs.tf
```

### Data-source references

When code contains:

```hcl
data.aws_caller_identity.current.account_id
```

look for the corresponding data block in the same Terraform root:

```hcl
data "aws_caller_identity" "current" {}
```

A Terraform data source reads information from AWS or another provider. It does
not represent an AWS resource owned by this Terraform state.

## Stack input flow

The normal Persistent input path is:

```text
Git-controlled environment configuration
    |
    +-- common-tags.tfvars
    |
    +-- persistent.tfvars
    |
    v
playbooks/terraform/config/persistent.yml
    |
    v
playbooks/terraform/common/deploy.yml
    |
    v
variables.tf
    |
    v
locals.tf
    |
    v
main.tf
```

`playbooks/terraform/config/persistent.yml` declares which tfvars files,
runtime-variable keys, dependencies, and destroy confirmation belong to the
Persistent lifecycle.

AAP also builds approved runtime values through:

```text
playbooks/terraform/tasks/runtime_variables.yml
```

Runtime variables cannot override lifecycle-owned cross-stack contracts.

## Organization tag flow

Organization tags follow this path:

```text
common-tags.tfvars / approved environment inventory
    |
    v
variables.tf
    |
    v
var.organization_tags
    |
    v
locals.tf
    |
    v
local.org_tags
    |
    +--> provider.tf default_tags
    |
    +--> resource-specific tag merges in main.tf
    |
    v
AWS resources
```

If an expected organization tag is missing, trace this flow before modifying
individual resources.

## Persistent Backup resources

The Backup vaults are long-lived recovery assets.

Creation flow:

```text
var.backup_vaults_enabled
    |
    v
main.tf
    |
    +--> module.backup_standard_vault
    |
    +--> module.backup_logically_air_gapped_vault
    |
    v
terraform/modules/backup-*-vault
```

The standard Backup vault is configured with:

```hcl
force_destroy = false
```

so retained recovery points are not implicitly deleted by Terraform.

The logically air-gapped vault uses explicit minimum and maximum retention
controls.

These resources intentionally survive normal disposable Recovery-stack
lifecycles.

## Network Firewall logging KMS

The optional Network Firewall logging KMS path is:

```text
var.network_firewall_logging_kms_enabled
    |
    v
main.tf
    |
    +--> data.aws_partition.current
    |
    +--> data.aws_caller_identity.current
    |
    +--> data.aws_iam_policy_document.network_firewall_logging_kms
    |
    v
module.network_firewall_logging_kms
    |
    v
terraform/modules/kms
```

The generated policy allows the regional CloudWatch Logs service to use the key
for the approved Network Firewall log-group prefix.

Temporary AAP/AWX STS assumed-role sessions are deliberately not added to the
KMS administration policy.

`kms_key_administrators` must therefore contain stable IAM role or user ARNs.

## Outputs and cross-stack dependencies

The Persistent cross-stack contract is defined in `outputs.tf`.

Current consumers are:

| Persistent output | Consumer |
|---|---|
| `network_firewall_logging_kms_key_arn` | Inspection |
| `standard_backup_vault_name` | Recovery |
| `air_gapped_backup_vault_arn` | Recovery |

The Network Firewall logging KMS output is consumed by the Inspection stack through AAP when customer-managed log encryption is enabled.

### Why cross-stack dependencies are different

A normal child-module reference can use:

```hcl
module.example.output_name
```

because the child module exists inside the same Terraform state and dependency
graph.

Persistent, Platform, Identity, Remote Access, and Recovery are separate
Terraform roots with separate Terraform states. They therefore cannot directly
reference each other's `module.*` objects.

AAP brokers approved outputs between those lifecycle states.

The flow is:

```text
Persistent main.tf
    |
    v
Persistent outputs.tf
    |
    v
ire/<environment>/persistent/terraform.tfstate
    |
    v
playbooks/terraform/tasks/read_dependency.yml
    |
    v
playbooks/terraform/tasks/runtime_variables.yml
    |
    v
approved downstream contract variable
    |
    v
Platform or Recovery Terraform root
```

For example:

```text
module.backup_standard_vault[0].name
    |
    v
output.standard_backup_vault_name
    |
    v
Persistent Terraform state
    |
    v
AAP dependency reader
    |
    v
Recovery persistent_resources.standard_backup_vault_name
```

Do not manually copy Persistent output values into downstream tfvars.

## Managed and external Persistent resources

`terraform_persistent_contract_source` is an AAP execution variable. It is not
a Terraform variable declared by this stack.

Supported modes are:

| Source | Behavior |
|---|---|
| `managed` | Downstream stacks read approved Persistent outputs from Terraform state |
| `external` | Downstream stacks consume explicitly approved external AWS resource references |

When the source is `external`, AAP does not read Persistent state for those
references.

External mode does not import, modify, or destroy the referenced AWS resources.

The Persistent stack itself must run only when the contract source is `managed`.

## Backend and state

`backend.tf` intentionally contains only the backend declaration:

```hcl
terraform {
  backend "s3" {}
}
```

The bucket, backend Region, and state key are not hardcoded into the Terraform
root.

AAP provides the backend bucket and Region and derives the Persistent state key
as:

```text
ire/<environment>/persistent/terraform.tfstate
```

Backend initialization is performed by the lifecycle engine under:

```text
playbooks/terraform/common/
```

Do not hardcode environment-specific backend values inside this Terraform root.

## Lifecycle safety

Plan and Apply use different fixed AAP entry points:

```text
playbooks/terraform/plan/persistent.yml
playbooks/terraform/apply/persistent.yml
```

The selected playbook fixes both the stack and the lifecycle operation.

Do not supply legacy stack-selection or apply-selection variables through Job
Template surveys.

Destroy uses:

```text
playbooks/terraform/destroy/persistent.yml
```

Actual destruction requires:

```yaml
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY PERSISTENT"
```

The exact expected confirmation is stored in:

```text
playbooks/terraform/config/persistent.yml
```

Persistent destruction should be treated as break-glass because these resources
are deliberately longer-lived than disposable recovery infrastructure.

Standard Backup vault deletion fails while recovery points remain because
`force_destroy=false`.

Compliance-locked Backup vaults and policy-protected KMS keys may remain
intentionally undeletable even after Terraform destruction is authorized.

## Troubleshooting reference map

| What appears in the code | Where to trace it |
|---|---|
| `var.foo` | `variables.tf`, then the approved tfvars or AAP source supplying it |
| `local.foo` | `locals.tf` |
| `module.foo` | matching module block in `main.tf` |
| `module.foo.bar` | matching child module under `terraform/modules/`, then its output |
| `data.aws_*` | matching data block in the current Terraform root |
| Root output | `outputs.tf` |
| Stack tfvars list | `playbooks/terraform/config/persistent.yml` |
| Environment value | `terraform/environments/<environment>/config/` |
| Missing dependency output | `playbooks/terraform/tasks/read_dependency.yml` |
| Wrong effective contract value | `playbooks/terraform/tasks/runtime_variables.yml` |
| Backend/state issue | AAP backend variables and `ire/<environment>/persistent/terraform.tfstate` |
| Missing organization tag | `variables.tf` -> `locals.tf` -> `provider.tf` / `main.tf` |
| Unexpected replacement | Terraform Plan; do not Apply until the reason is understood |

## Troubleshooting a normal Terraform value

When an unexpected value appears, trace it in this order:

```text
1. environment tfvars or approved AAP input
2. variables.tf
3. locals.tf
4. main.tf
5. reusable child module
6. child-module output
7. Persistent outputs.tf
```

For example, if this is unexpected:

```hcl
local.standard_backup_vault_name
```

trace:

```text
terraform/environments/<environment>/config/persistent.tfvars
    |
    v
var.name_prefix
    |
    v
locals.tf
    |
    v
local.standard_backup_vault_name
```

## Troubleshooting a cross-stack value

If Recovery cannot obtain a Persistent Backup vault reference, trace:

```text
Persistent outputs.tf
    |
    v
Persistent state
    |
    v
playbooks/terraform/config/recovery.yml
    |
    v
playbooks/terraform/tasks/read_dependency.yml
    |
    v
playbooks/terraform/tasks/runtime_variables.yml
    |
    v
Recovery persistent_resources input
```

Confirm that:

1. the upstream Persistent state exists;
2. the expected output exists in that state;
3. the downstream stack declares that dependency in its AAP stack config;
4. the dependency reader is using the expected backend key; and
5. the runtime contract contains the expected value.

Do not work around a missing dependency by manually copying state outputs into
tfvars.

## Troubleshooting an unexpected plan

For an unexpected create, update, replacement, or destroy:

```text
Environment configuration
    |
    v
Variable declaration
    |
    v
Derived local
    |
    v
Root module call
    |
    v
Reusable module
    |
    v
Terraform state
    |
    v
Plan
```

Confirm:

1. the selected environment;
2. the selected lifecycle stack;
3. the backend key;
4. the Git-controlled tfvars;
5. approved AAP runtime variables;
6. the affected variable/local/module chain;
7. current Terraform state ownership; and
8. any downstream contract impact.

Stop on unexplained replacement or destruction.

Do not blindly Apply, Destroy, Import, remove resources from state, or push
modified state to resolve unexplained drift.

## Stable names

The Sandbox currently retains its historical resource-name prefix:

```hcl
name_prefix = "ire-sandbox-foundation"
```

The Terraform stack rename did not rename those existing AWS resources.

Changing this prefix may force replacement and therefore requires a separate,
reviewed migration.

## Local validation

Format the stack:

```bash
terraform fmt -check -recursive terraform/stacks/persistent
```

Validate the Terraform configuration:

```bash
terraform -chdir=terraform/stacks/persistent validate
```

Local validation checks Terraform syntax and module/provider consistency.

Backend, account, state, and runtime contract validation remain owned by the
approved AAP Plan workflow.
