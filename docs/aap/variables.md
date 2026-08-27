# AAP and Terraform Variable Ownership

AAP executes and orchestrates Terraform. Git remains the source of truth for
stable IRE architecture and capability enablement.

## Ownership model

| Layer | Owner | Examples |
|---|---|---|
| Desired architecture | Git / Pull Request | topology, naming, tags, Client VPN mode, persistent capability flags |
| Security policy | Git / Pull Request | security-group rules, Network Firewall rules, KMS policy scope |
| Environment binding | Git-controlled AAP inventory | role, Regions, backend bucket, target account, Persistent contract source |
| Runtime intent | Fixed JT / approved survey | plan/apply, temporary workload enablement, destroy authorization |
| External runtime binding | Fixed JT / approved survey | certificates and externally owned platform references |
| Secrets | AAP Credential / approved secret manager | bootstrap credentials, protected tokens and private material |

## Git-controlled stack configuration

| Stack | Files |
|---|---|
| Persistent | `common-tags.tfvars`, `persistent.tfvars` |
| Platform | `common-tags.tfvars`, `platform.tfvars`, `platform-network-policy.tfvars` |
| Identity | `common-tags.tfvars`, `identity.tfvars` |
| Recovery | `common-tags.tfvars`, `recovery.tfvars` |

Persistent capability flags are Git controlled:

~~~hcl
backup_vaults_enabled                = false
network_firewall_logging_kms_enabled = false
~~~

They can be enabled independently through a reviewed Git change. They are not
launch-time AAP survey inputs.

## SCM inventory environment bindings

Every normal deploy or destroy JT selects an approved SCM-sourced AAP
inventory. The inventory supplies these top-level Ansible variables:

| Variable | Required | Purpose |
|---|---:|---|
| `terraform_environment` | Yes | Approved environment; currently `sandbox` |
| `assume_role_role_arn` | Yes | Approved Terraform execution role |
| `assume_role_aws_region` | Yes | Deployment Region; source for Terraform `aws_region` |
| `assume_role_application_name` | Yes | Auditable session prefix, normally `ire-terraform` |
| `assume_role_expected_account_id` | Yes | Twelve-digit target account guard |
| `terraform_backend_bucket` | Yes | Approved S3 state bucket |
| `terraform_backend_region` | Yes | Region containing the state bucket |
| `terraform_persistent_contract_source` | Yes | `managed` outputs or approved `external` references |
| `terraform_external_persistent_resources` | Yes | Mapping; use `{}` when unused |

The customer-neutral inventory structure is under `inventories/example/`.
Real account, role, backend, and external-resource values belong only in the
private deployment-configuration repository. Do not repeat inventory-owned
values in individual JTs.

Every JT supplies only:

| Variable | Required | Purpose |
|---|---:|---|
| `terraform_stack` | Yes | Fixed JT value: `persistent`, `platform`, `identity`, or `recovery` |
| Lifecycle flag | Yes | Fixed plan/apply or destroy intent |
| `terraform_variables` | Yes | Stack-specific allowlisted runtime map; use `{}` when empty |
| Destroy gate | Destroy only | Stack-specific allow Boolean and confirmation |

The playbooks derive Terraform root and backend key internally. Never supply
`terraform_root`, `terraform_backend_key`, `persistent_resources`, or
`platform_contract` through `terraform_variables`.

## Persistent contract selection

These are top-level environment inventory variables, not members of
`terraform_variables`:

| Variable | Source | Purpose |
|---|---|---|
| `terraform_persistent_contract_source` | Required | Selects managed Terraform outputs or external AWS references |
| `terraform_external_persistent_resources` | Required | Approved external references used only in `external` mode; otherwise `{}` |

Managed mode:

~~~yaml
terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
~~~

External KMS only:

~~~yaml
terraform_persistent_contract_source: external
terraform_external_persistent_resources:
  network_firewall_logging_kms_key_arn: >-
    arn:aws:kms:us-east-2:111122223333:key/00000000-0000-0000-0000-000000000000
~~~

External Backup vaults only:

~~~yaml
terraform_persistent_contract_source: external
terraform_external_persistent_resources:
  standard_backup_vault_name: "approved-standard-vault"
  air_gapped_backup_vault_arn: >-
    arn:aws:backup:us-east-2:111122223333:backup-vault:approved-airgap-vault
~~~

Unused keys may be omitted. Platform logging accepts a missing KMS ARN and uses
CloudWatch Logs default encryption. Recovery requires both vault references
only when Git enables `backup_integration_enabled`.

The Persistent stack itself is valid only with source `managed`. External mode
is a consumer binding and never manages external resources.

## Sandbox terraform_variables allowlist

| Stack | Allowed keys | Required condition |
|---|---|---|
| Persistent | `kms_key_administrators` | Required only when managed logging KMS creation is enabled |
| Platform | `server_certificate_arn`, `root_certificate_chain_arn`, `saml_provider_arn`, `ssm_instance_profile_name` | Depends on Git-selected Client VPN and SSM modes |
| Identity | None | Supply `{}` |
| Recovery | `demo_ec2_enabled` | Enables only the workloads already reviewed in Git |

Examples:

~~~yaml
# Persistent with KMS capability disabled
terraform_variables: {}

# Persistent with KMS capability enabled in Git
terraform_variables:
  kms_key_administrators:
    - "arn:aws:iam::111122223333:role/approved-kms-administrator"

# Recovery exercise
terraform_variables:
  demo_ec2_enabled: true
~~~

## Identity sensitive credential

Identity accepts no ordinary Sandbox runtime-variable overrides. Keep:

~~~yaml
terraform_variables: {}
~~~

When Git enables Managed AD, attach an approved AAP custom credential to the
Identity Plan, Apply, and Destroy Job Templates. The credential injects the
bootstrap password through the protected
`IRE_TERRAFORM_MANAGED_AD_PASSWORD` environment variable.

The playbooks:

- reject `managed_ad_password` if an operator supplies it through
  `terraform_variables`;
- read the credential environment under `no_log`;
- add the password only to the internal Terraform variable document;
- write that document with mode `0600`; and
- remove the temporary variable and plan files in an `always` block.

When Managed AD is disabled, the Identity stack remains valid without this
credential. Never store the password in inventory, SCM, Job Template YAML, or
ordinary extra variables.

See ADR-002 and the Managed Microsoft AD module README for the bootstrap
password and Terraform-state limitation.

## Recovery workload compute contract

`terraform/environments/sandbox/config/recovery.tfvars` owns every workload's
AMI and administrative access configuration. AAP cannot replace those values
through the normal Sandbox runtime map.

~~~hcl
recovery_workloads = {
  core_01 = {
    server_name   = "A2NIRECORE001"
    ami_id        = "ami-00000000000000000"
    access_method = "ssm"

    vpc_key   = "core_recovery"
    subnet_key = "recovery_services_a"

    security_group_keys = ["core"]
    backup_enabled      = true
  }
}
~~~

Supported access methods are:

| Value | Instance profile | EC2 key pair | Purpose |
|---|---:|---:|---|
| `none` | No | No | No interactive administrative path configured by Recovery |
| `ssm` | Yes | No | Standard auditable administration path |
| `ssh_key` | No | Yes | Controlled SSH-only exception |
| `ssm_with_ssh_fallback` | Yes | Yes | SSM primary with an explicitly approved dormant SSH fallback |

SSH workloads reference `recovery_ssh_key_pairs` by key-pair name. An
`existing` entry performs a read-only AWS lookup. A `managed` entry imports a
public key file available inside the AAP project. Terraform never receives the
matching private key.

~~~hcl
recovery_ssh_key_pairs = {
  existing-ire-admin = {
    source = "existing"
  }

  ire-lab-admin = {
    source          = "managed"
    public_key_path = "../../environments/sandbox/keys/ire-lab-admin.pub"
  }
}
~~~

SSM requires a suitable instance profile, SSM Agent in the selected AMI, DNS,
and outbound connectivity through the required interface endpoints or another
approved path. SSH additionally requires an approved network route and
security-group rule; attaching a key pair does not open TCP/22.

## Capability behavior matrix

| Contract source | Managed vault flag | Managed KMS flag | Platform | Recovery |
|---|---:|---:|---|---|
| `managed` | `false` | `false` | No CMK contract; default log encryption | Backup integration must remain disabled |
| `managed` | `false` | `true` | Uses managed CMK when logging is enabled | Backup integration must remain disabled |
| `managed` | `true` | `false` | Default log encryption | Uses managed vault outputs when backup integration is enabled |
| `managed` | `true` | `true` | Uses managed CMK | Uses managed vault outputs |
| `external` | Not applicable | Not applicable | Uses supplied CMK ARN or default encryption | Uses supplied vault references or keeps backup integration disabled |

## Deploy intent

~~~yaml
# Plan
terraform_apply_enabled: false

# Approved apply
terraform_apply_enabled: true
~~~

## Destroy intent

Destroy-plan JTs always use:

~~~yaml
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
~~~

Actual destroy authorization:

| Stack | Additional variables |
|---|---|
| Recovery | `terraform_destroy_enabled: true`, `terraform_allow_recovery_destroy: true`, confirmation `DESTROY RECOVERY` |
| Identity | `terraform_destroy_enabled: true`, `terraform_allow_identity_destroy: true`, confirmation `DESTROY IDENTITY` |
| Platform | `terraform_destroy_enabled: true`, `terraform_allow_platform_destroy: true`, confirmation `DESTROY PLATFORM` |
| Persistent | `terraform_destroy_enabled: true`, `terraform_allow_persistent_destroy: true`, confirmation `DESTROY PERSISTENT` |
| Client VPN AD POC | `terraform_destroy_enabled: true`, `terraform_allow_client_vpn_ad_poc_destroy: true`, confirmation `DESTROY CLIENT VPN AD POC` |

Destroy must receive the same Git configuration, runtime Terraform variables,
and contract source used to evaluate the deployed stack. External references
remain outside the Terraform destroy boundary.

## Sensitive values

Never place credentials, passwords, private keys, access keys, or protected
tokens in Git variable files or JT examples. Use AAP Credentials or the
approved enterprise secret-management mechanism.

AWS account IDs, role ARNs, Regions, backend bucket names, certificate ARNs,
and external resource ARNs are identifiers rather than authentication secrets.
Store real values only in the approved private configuration repository unless
organizational classification policy requires stronger handling.
