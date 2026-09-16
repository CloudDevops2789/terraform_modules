# Identity Stack

This Terraform root owns IRE identity services whose lifecycle is separate from
Platform networking and temporary Recovery workloads.

The primary capability is AWS Managed Microsoft AD. Optional private Route 53
Resolver integration is owned here because it depends directly on the directory
DNS namespace and runtime directory outputs.

## Ownership

When enabled, this stack can manage:

- AWS Managed Microsoft AD;
- additive directory client-network access rules;
- a Route 53 Resolver outbound endpoint;
- DNS forwarding rules for the Managed AD namespace;
- Resolver security groups and rules; and
- optional Resolver query-log associations.

It does not own:

- VPCs, subnets, Transit Gateway, or routing;
- Network Firewall;
- Client VPN;
- persistent Backup vaults;
- recovery compute.

Platform networking is consumed through a narrow cross-stack contract.

## Repository layout

```text
terraform/stacks/identity/
├── backend.tf      # Backend declaration; runtime backend values come from AAP
├── provider.tf     # AWS Region and provider-level tags
├── versions.tf     # Terraform and AWS provider requirements
├── variables.tf    # Complete typed Identity input contract
├── locals.tf       # Tags and Platform topology resolution
├── main.tf         # Managed AD and private DNS composition
├── outputs.tf      # Identity contract outputs
└── README.md       # Ownership, dependency flow, and troubleshooting
```

Terraform loads all `*.tf` files in this directory together as one root module.

`main.tf` does not call `locals.tf` or `variables.tf`. Terraform builds its
dependency graph from references.

## Platform dependency

Identity does not hardcode AWS VPC IDs or subnet IDs.

The approved Platform contract is produced by the Platform stack and passed to
Identity through AAP:

```text
Platform main/resources
    |
    v
Platform outputs.tf
    |
    v
ire/<environment>/platform/terraform.tfstate
    |
    v
playbooks/terraform/config/identity.yml
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
locals.tf
    |
    +--> local.identity_platform_placement
    |
    +--> local.managed_ad_dns_resolver_placement
    |
    v
main.tf
```

Identity therefore depends on the logical topology contract, not on fixed VPC,
subnet, CIDR, or Availability Zone values.

## Managed AD placement

Environment configuration supplies logical selectors through
`identity_placement`.

Example flow:

```text
identity.tfvars
    |
    v
var.identity_placement.vpc_key
var.identity_placement.subnet_group
    |
    v
var.platform_contract
    |
    v
locals.tf
    |
    v
local.identity_platform_placement
    |
    +--> resolved VPC ID
    |
    +--> resolved subnet IDs
    |
    v
module.managed_microsoft_ad
```

If placement fails, confirm that the requested logical VPC and subnet group
exist in the Platform contract.

## Managed AD configuration

Managed AD is controlled by:

```text
var.managed_ad_enabled
var.managed_ad_configuration
var.identity_placement
var.platform_contract
var.managed_ad_password
```

The password is sensitive and must come from the approved AAP credential path.
It must not be committed to tfvars or inventory.

The child module is:

```text
terraform/modules/managed-microsoft-ad
```

and is called from `main.tf` as:

```hcl
module "managed_microsoft_ad" {
  ...
}
```

## Directory client-network access

`managed_ad_client_vpc_keys` contains logical Platform VPC keys that may use
native Active Directory services.

The flow is:

```text
managed_ad_client_vpc_keys
    |
    v
var.platform_contract.vpc_cidrs
    |
    v
main.tf
    |
    v
module.managed_microsoft_ad.client_cidr_blocks
```

The directory placement VPC is excluded from these additive rules because AWS
owns the baseline directory security-group rules for that placement.

## Private DNS Resolver integration

The optional Resolver integration is controlled through
`managed_ad_dns_resolver`.

Enablement is normalized in `locals.tf`:

```text
var.managed_ad_enabled
        +
var.managed_ad_dns_resolver.enabled
        |
        v
local.managed_ad_dns_resolver_enabled
```

Placement is resolved through the Platform contract:

```text
var.managed_ad_dns_resolver.vpc_key
var.managed_ad_dns_resolver.subnet_group
        |
        v
var.platform_contract
        |
        v
local.managed_ad_dns_resolver_placement
```

The Resolver composition in `main.tf` creates:

```text
Resolver security group
    |
    v
DNS security-group rules
    |
    v
Route 53 Resolver outbound endpoint
    |
    v
forwarding rule for Managed AD domain
```

## Internal Managed AD to Resolver dependency

The Resolver depends on runtime outputs from Managed AD.

```text
module.managed_microsoft_ad
    |
    +--> directory_name
    |
    +--> dns_ip_addresses
    |
    +--> security_group_id
    |
    v
Resolver security rules and forwarding configuration
```

Examples:

```hcl
module.managed_microsoft_ad[0].directory_name
module.managed_microsoft_ad[0].dns_ip_addresses
module.managed_microsoft_ad[0].security_group_id
```

These are same-state module dependencies and are resolved directly by
Terraform.

They are different from the Platform-to-Identity dependency, which crosses
Terraform state boundaries and is brokered by AAP.

## Organization tag flow

Organization tags follow:

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
local.org_tags
    |
    +--> provider.tf default_tags
    |
    +--> module tags in main.tf
```

## Outputs and downstream contract

Identity exports both operational outputs and a narrow `identity_contract`.

Important values include:

```text
directory_id
directory_name
dns_ip_addresses
security_group_id
identity_contract
```

The cross-state flow is:

```text
main.tf
    |
    v
outputs.tf
    |
    v
ire/<environment>/identity/terraform.tfstate
    |
    v
AAP dependency reader
    |
    v
downstream consumer
```

The `identity_contract` is intentionally narrow and is suitable for consumers
such as Remote Access without exposing the entire Identity state.

## Backend and state

`backend.tf` declares:

```hcl
terraform {
  backend "s3" {}
}
```

AAP supplies runtime backend values.

The Identity state key is:

```text
ire/<environment>/identity/terraform.tfstate
```

Do not hardcode backend bucket names, Regions, account bindings, or state keys
inside this root.

## Lifecycle entry points

Plan:

```text
playbooks/terraform/plan/identity.yml
```

Apply:

```text
playbooks/terraform/apply/identity.yml
```

Destroy:

```text
playbooks/terraform/destroy/identity.yml
```

Normal Identity Apply has an additional safety guard.

The saved Terraform plan is inspected by:

```text
playbooks/terraform/tasks/guard_identity_plan.yml
```

A normal Identity Apply is rejected when the plan contains deletion or
replacement actions.

Intentional removal must use the separately authorized Identity Destroy
workflow.

## Troubleshooting reference map

| What you see | Where to trace it |
|---|---|
| `var.foo` | `variables.tf`, then approved tfvars/AAP source |
| `local.foo` | `locals.tf` |
| `module.managed_microsoft_ad` | `main.tf`, then `terraform/modules/managed-microsoft-ad` |
| `module.managed_ad_dns_resolver` | `main.tf`, then `terraform/modules/route53-resolver` |
| `var.platform_contract` | Platform state -> AAP dependency reader -> runtime variables |
| Placement problem | `identity_placement` / resolver placement -> `platform_contract` -> `locals.tf` |
| Missing Platform output | `terraform/stacks/platform/outputs.tf` and Platform state |
| Missing dependency | `playbooks/terraform/config/identity.yml` |
| Dependency state read failure | `playbooks/terraform/tasks/read_dependency.yml` |
| Wrong effective contract | `playbooks/terraform/tasks/runtime_variables.yml` |
| Unexpected Identity deletion/replacement | Plan plus `guard_identity_plan.yml` |
| Missing DNS forwarding | Resolver settings -> Platform placement -> Managed AD outputs -> Resolver modules |
| Missing tag | tagging variables -> `locals.tf` -> provider/module tags |

## Troubleshooting Platform placement

If Identity reports that placement cannot resolve, trace:

```text
terraform/environments/<environment>/config/identity.tfvars
    |
    v
var.identity_placement
    |
    v
var.platform_contract
    |
    v
local.identity_platform_placement
```

Check that:

1. the requested `vpc_key` exists in `platform_contract.vpc_ids`;
2. the requested `subnet_group` exists for that VPC;
3. enough subnets exist for `required_subnet_count`; and
4. the Platform state being read is the expected environment/state key.

Do not replace logical selectors with manually copied VPC or subnet IDs.

## Troubleshooting DNS Resolver

If Managed AD exists but DNS Resolver provisioning fails, trace:

```text
managed_ad_dns_resolver configuration
    |
    v
local.managed_ad_dns_resolver_enabled
    |
    v
local.managed_ad_dns_resolver_placement
    |
    v
Resolver security group
    |
    v
Resolver security rules
    |
    v
module.managed_microsoft_ad outputs
    |
    v
Route 53 Resolver module
```

Confirm:

1. Managed AD is enabled;
2. Resolver integration is enabled;
3. Platform placement resolves;
4. associated VPC keys exist in the Platform contract;
5. Managed AD exposes directory name, DNS IPs, and security group ID; and
6. optional query-log configuration is valid.

## Troubleshooting an unexpected plan

For any unexpected create, update, replacement, or delete:

```text
identity.tfvars / AAP runtime input
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
Terraform state
    |
    v
plan
```

Confirm environment, backend key, Platform dependency state, logical placement,
credential injection, and current state ownership.

Stop on unexplained replacement or deletion.

Do not blindly Apply, Destroy, Import, remove resources from state, or push
modified state to work around unexplained drift.

## Local validation

Initialize without configuring the backend when local modules are not yet
registered:

```bash
terraform -chdir=terraform/stacks/identity init -backend=false -input=false
```

Validate:

```bash
terraform -chdir=terraform/stacks/identity validate
```

Format:

```bash
terraform fmt -check -recursive terraform/stacks/identity
```

Runtime backend, state, account, and contract validation remain owned by the
approved AAP Plan workflow.
