# Persistent Resources Stack

This Terraform root owns optional IRE resources whose lifecycle is deliberately
longer than the Platform, Identity, and Recovery stacks.

It is named `persistent` because lifecycle is the shared characteristic. It is
not an account or network foundation stack.

## Ownership

When enabled, this stack can manage:

- a standard AWS Backup vault;
- a logically air-gapped AWS Backup vault; and
- a customer-managed KMS key for Network Firewall CloudWatch log encryption.

It does not own VPCs, routing, Network Firewall, identities, backup plans, or
recovery workloads.

## Capabilities

Capabilities are independent and Git controlled.

| Variable | Default | Effect |
|---|---:|---|
| `backup_vaults_enabled` | `false` | Creates both persistent Backup vaults |
| `network_firewall_logging_kms_enabled` | `false` | Creates the optional logging KMS key |

The KMS key is not required by AWS Network Firewall. When Platform logging is
enabled without a KMS ARN, CloudWatch Logs uses its default server-side
encryption.

`kms_key_administrators` is required through AAP only when
`network_firewall_logging_kms_enabled=true`. Values must be stable IAM role or
user ARNs; STS assumed-role session ARNs are rejected.

## Stable names

The Sandbox retains this historical prefix:

~~~hcl
name_prefix = "ire-sandbox-foundation"
~~~

The stack rename does not rename existing AWS resources. Changing the prefix
requires a separate reviewed migration because it can force replacement.

## Outputs

| Output | Consumer | Disabled value |
|---|---|---|
| `network_firewall_logging_kms_key_arn` | Platform | `null` |
| `standard_backup_vault_name` | Recovery | `null` |
| `air_gapped_backup_vault_arn` | Recovery | `null` |

The AAP lifecycle contract broker presents the same `persistent_resources`
object to consumers whether references come from managed Terraform outputs or
from approved external AWS resources.

## Managed and external modes

`terraform_persistent_contract_source` is an AAP variable, not a Terraform
variable.

| Source | Behavior |
|---|---|
| `managed` | Platform and Recovery read approved outputs from `ire/<environment>/persistent/terraform.tfstate` |
| `external` | Platform and Recovery use `terraform_external_persistent_resources`; the Persistent stack is not run |

External mode never imports, changes, or destroys the referenced AWS resources.
It only passes their approved identifiers to consumer stacks.

## Lifecycle safety

- Plan is the default AAP operation.
- Managed creation requires `terraform_apply_enabled=true`.
- Persistent destroy requires all of:
  `terraform_destroy_enabled=true`,
  `terraform_allow_persistent_destroy=true`, and
  `terraform_destroy_confirmation="DESTROY PERSISTENT"`.
- Standard vault deletion fails while recovery points exist because
  `force_destroy=false`.
- Compliance-locked vaults and SCP-protected KMS keys may be intentionally
  undeletable even after Terraform destroy is authorized.
- External resources are outside this stack's destroy boundary.

## Local validation

~~~bash
terraform fmt -check -recursive terraform/stacks/persistent
terraform -chdir=terraform/stacks/persistent validate
~~~
