# Recovery Stack

The Recovery stack owns temporary workload infrastructure and recovery-specific
AWS Backup policy used during IRE recovery exercises or actual recovery events.

It is intentionally disposable. Long-lived Backup vaults and core networking
belong to other lifecycle stacks.

## Ownership

Recovery can manage:

- temporary EC2 recovery workloads;
- approved existing or Terraform-managed EC2 SSH key registrations;
- AWS Backup plans;
- AWS Backup execution role;
- AWS Backup workload selections.

Recovery does not own:

- VPCs, subnets, routing, or Transit Gateway;
- platform security groups or SSM management infrastructure;
- persistent Backup vaults;
- AWS Managed Microsoft AD;
- Network Firewall.

## Repository layout

```text
terraform/stacks/recovery/
├── backend.tf      # Backend declaration; runtime values come from AAP
├── provider.tf     # AWS Region and provider-level tags
├── versions.tf     # Terraform and provider requirements
├── variables.tf    # Complete typed Recovery input contract
├── locals.tf       # Naming, tags, SSH-key resolution, Backup defaults
├── main.tf         # Compute and Backup composition
├── outputs.tf      # Recovery runtime outputs
└── README.md       # Ownership, dependency flow, and troubleshooting
```

Terraform loads all `*.tf` files in this directory together as one root module.

`main.tf` does not call `locals.tf` or `variables.tf`. References create the
dependency graph.

## Recovery dependency model

Recovery consumes two upstream lifecycle contracts.

```text
                    Platform state
                         |
                         v
                  var.platform_contract
                         |
                         v
                  Recovery compute
                         |
                         v
                    EC2 instances
                         |
                         +-------------------+
                                             |
                                             v
Persistent state                     Backup selection
      |                                      |
      v                                      v
var.persistent_resources             Recovery Backup plan
      |                                      |
      +--------------------------------------+
```

Platform and Persistent dependencies cross Terraform state boundaries and are
brokered by AAP.

Dependencies between Recovery EC2 and Recovery Backup selection are same-state
Terraform dependencies and are resolved directly by Terraform.

## Platform dependency

Recovery does not hardcode subnet IDs, security-group IDs, or SSM instance
profiles.

The Platform contract reaches Recovery through:

```text
Platform outputs.tf
    |
    v
ire/<environment>/platform/terraform.tfstate
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
var.platform_contract
    |
    v
main.tf
```

The Platform contract provides:

```text
subnet_ids
subnet_ids_by_group
security_group_ids
ssm_instance_profile_name
```

Workloads select infrastructure using logical keys rather than manually copied
AWS IDs.

## Recovery workload flow

Workload configuration is defined through `recovery_workloads`.

```text
recovery.tfvars
    |
    v
var.recovery_workloads
    |
    +--> AMI
    +--> instance type
    +--> logical VPC key
    +--> logical subnet selector
    +--> logical security-group keys
    +--> access method
    +--> backup intent
    |
    v
main.tf
    |
    v
module.ec2
```

When `demo_ec2_enabled=false`, temporary EC2 workloads are not created.

## Workload placement

A workload selects either:

- one exact logical subnet key; or
- one logical subnet group plus an index.

The selected logical values are resolved through `var.platform_contract`.

Example:

```text
workload.vpc_key
workload.subnet_group
workload.subnet_index
        |
        v
var.platform_contract.subnet_ids_by_group
        |
        v
actual AWS subnet ID
```

Security groups resolve similarly:

```text
workload.security_group_keys
        |
        v
var.platform_contract.security_group_ids
        |
        v
actual AWS security-group IDs
```

Do not replace these logical selectors with hardcoded AWS IDs in
`recovery.tfvars`.

## Administrative access

Supported workload access methods are:

```text
none
ssm
ssh_key
ssm_with_ssh_fallback
```

SSM workloads consume:

```text
var.platform_contract.ssm_instance_profile_name
```

SSH workloads reference the approved `recovery_ssh_key_pairs` registry.

## SSH key resolution

Recovery supports two SSH-key sources.

### Existing key

```text
recovery_ssh_key_pairs
    |
    v
source = existing
    |
    v
data.aws_key_pair.recovery_existing
    |
    v
local.recovery_ssh_key_names
```

### Managed key registration

```text
recovery_ssh_key_pairs
    |
    v
source = managed
    |
    v
public_key_path
    |
    v
module.key_pair
    |
    v
local.recovery_ssh_key_names
```

Only keys actually referenced by enabled SSH-capable workloads are resolved.

Private SSH keys are not managed by this Terraform stack.

## Persistent Backup dependency

Backup vaults are intentionally owned by the Persistent lifecycle.

Recovery receives only the approved identifiers it needs:

```text
Persistent outputs.tf
    |
    v
ire/<environment>/persistent/terraform.tfstate
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
var.persistent_resources
```

The contract contains:

```text
standard_backup_vault_name
air_gapped_backup_vault_arn
```

Recovery does not import or own those vaults.

## Backup policy flow

When `backup_integration_enabled=true`:

```text
local.backup
    |
    +--> Backup schedule
    +--> retention
    +--> copy lifecycle
    |
    v
module.backup_plan
```

The standard Persistent vault is the primary Backup target.

The logically air-gapped Persistent vault is used by the cyber-recovery copy
action.

## Same-state EC2 to Backup dependency

Recovery EC2 and Backup selection live in the same Terraform state.

Therefore this dependency is resolved directly by Terraform:

```text
module.ec2.instance_arns
    |
    v
module.backup_selection.resources
```

Only workloads with:

```hcl
backup_enabled = true
```

are included in the Backup selection.

This is intentionally an explicit ARN selection rather than broad tag-based
selection.

## Naming flow

Recovery resource names are derived through `locals.tf`.

```text
var.naming
    |
    +--> organization
    +--> project
    +--> environment
    +--> region code
    +--> optional suffix
    |
    v
local.name_prefix
    |
    v
local.resource_names
```

Exact Backup resource names can be overridden through
`resource_name_overrides`.

Changing names can cause replacement and must be reviewed through Terraform
Plan.

## Organization tag flow

```text
common-tags.tfvars / approved environment inventory
    |
    v
variables.tf
    |
    v
local.org_default_tags
    +
var.org_additional_tags
    |
    v
local.org_tags
    |
    +--> provider.tf default_tags
    |
    +--> module tags in main.tf
```

## Backend and state

The backend declaration remains intentionally generic:

```hcl
terraform {
  backend "s3" {}
}
```

AAP supplies backend values and derives:

```text
ire/<environment>/recovery/terraform.tfstate
```

Do not hardcode backend bucket names, Regions, account IDs, or state keys in
this root.

## Lifecycle entry points

Plan:

```text
playbooks/terraform/plan/recovery.yml
```

Apply:

```text
playbooks/terraform/apply/recovery.yml
```

Destroy:

```text
playbooks/terraform/destroy/recovery.yml
```

Recovery is expected to be more disposable than Persistent or Identity, but
destruction still requires the explicitly authorized destroy workflow.

## Troubleshooting reference map

| What you see | Where to trace it |
|---|---|
| `var.foo` | `variables.tf`, then approved tfvars/AAP source |
| `local.foo` | `locals.tf` |
| `module.ec2` | `main.tf`, then `terraform/modules/ec2` |
| `module.backup_plan` | `main.tf`, then `terraform/modules/backup-plan` |
| `var.platform_contract` | Platform state -> AAP dependency reader -> runtime variables |
| `var.persistent_resources` | Persistent state -> AAP dependency reader -> runtime variables |
| Wrong subnet | workload selector -> Platform contract |
| Wrong security group | workload security-group key -> Platform contract |
| SSM unavailable | workload access method -> Platform SSM instance profile |
| SSH key failure | `recovery_ssh_key_pairs` -> locals -> key data/module |
| Missing Backup vault | Persistent outputs/state -> AAP dependency reader |
| Workload missing from Backup | `backup_enabled` -> EC2 ARN -> Backup selection |
| Wrong Backup schedule | `local.backup` |
| Wrong resource name | `var.naming` / overrides -> `local.resource_names` |
| Unexpected replacement | Terraform Plan; stop before Apply |

## Troubleshooting workload placement

Trace:

```text
recovery.tfvars
    |
    v
var.recovery_workloads
    |
    v
var.platform_contract
    |
    v
main.tf
    |
    v
module.ec2
```

Confirm:

1. the workload VPC key exists in Platform;
2. the selected subnet or subnet group exists;
3. the subnet index is valid;
4. every security-group key exists;
5. the selected access method has its required Platform capability.

Do not work around a placement failure by copying raw subnet or security-group
IDs into configuration.

## Troubleshooting Backup integration

Trace:

```text
Persistent outputs
    |
    v
Persistent state
    |
    v
var.persistent_resources
    |
    v
module.backup_plan
    |
    v
module.ec2.instance_arns
    |
    v
module.backup_selection
```

Confirm:

1. Backup integration is enabled;
2. Recovery EC2 is enabled;
3. at least one workload has `backup_enabled=true`;
4. Persistent vault outputs exist;
5. the standard vault name is populated;
6. the air-gapped vault ARN is valid;
7. selected EC2 instance ARNs exist.

Do not manually copy vault identifiers into Recovery tfvars to bypass a broken
dependency contract.

## Troubleshooting an unexpected plan

For unexpected create, update, replacement, or deletion:

```text
recovery.tfvars / AAP runtime input
    |
    v
variables.tf
    |
    v
locals.tf
    |
    v
main.tf
    |
    v
child module
    |
    v
Recovery state
    |
    v
Terraform Plan
```

Also inspect the relevant upstream contract when the affected resource depends
on Platform or Persistent.

Stop on unexplained replacement or destruction.

Do not blindly Apply, Destroy, Import, remove resources from state, or push
modified state to resolve unexplained drift.

## Local validation

Initialize locally without configuring the backend when needed:

```bash
terraform -chdir=terraform/stacks/recovery init -backend=false -input=false
```

Validate:

```bash
terraform -chdir=terraform/stacks/recovery validate
```

Format:

```bash
terraform fmt -check -recursive terraform/stacks/recovery
```

Runtime backend, state, AWS account, and cross-stack contract validation remain
owned by the approved AAP Plan workflow.
