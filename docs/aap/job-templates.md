# AAP Job Template Design

AAP uses two reusable lifecycle playbooks:

| Playbook | Purpose |
|---|---|
| `playbooks/terraform_deploy.yml` | Terraform plan and approved apply |
| `playbooks/terraform_destroy.yml` | Destroy plan and explicitly authorized destroy |

Do not create a separate playbook per stack. Do not combine deploy and destroy
into one playbook. Fixed stack-specific JTs provide clear RBAC, audit history,
troubleshooting, and protection from selecting the wrong stack at launch.

## Common fixed variables

Each JT fixes these values in Template or Inventory configuration:

~~~yaml
terraform_environment: sandbox
terraform_stack: "<persistent|platform|identity|recovery>"

assume_role_role_arn: "<APPROVED_TERRAFORM_ROLE_ARN>"
assume_role_aws_region: "us-east-2"
assume_role_application_name: "ire-terraform"
assume_role_expected_account_id: "<12_DIGIT_ACCOUNT_ID>"

terraform_backend_bucket: "<APPROVED_STATE_BUCKET>"
terraform_backend_region: "<BACKEND_BUCKET_REGION>"

terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
terraform_variables: {}
~~~

`terraform_stack` must not be exposed as a free-form survey variable. Backend
key and Terraform root are derived internally and must not be supplied.

## Recommended fixed Job Templates

Create four JTs per stack. This gives 16 predictable templates backed by only
the two reusable playbooks.

| Stack | Plan | Apply | Destroy plan | Destroy |
|---|---|---|---|---|
| Persistent | `IRE-Persistent-Plan` | `IRE-Persistent-Apply` | `IRE-Persistent-Destroy-Plan` | `IRE-Persistent-Destroy` |
| Platform | `IRE-Platform-Plan` | `IRE-Platform-Apply` | `IRE-Platform-Destroy-Plan` | `IRE-Platform-Destroy` |
| Identity | `IRE-Identity-Plan` | `IRE-Identity-Apply` | `IRE-Identity-Destroy-Plan` | `IRE-Identity-Destroy` |
| Recovery | `IRE-Recovery-Plan` | `IRE-Recovery-Apply` | `IRE-Recovery-Destroy-Plan` | `IRE-Recovery-Destroy` |

Plan JTs fix `terraform_apply_enabled: false`. Apply JTs fix
`terraform_apply_enabled: true`. Do not expose this Boolean through the normal
plan template survey.

Destroy-plan JTs fix `terraform_destroy_enabled: false`. Actual destroy JTs fix
the stack-specific confirmation and elevated allow flag shown below.

## Stack deploy variables

### Persistent managed plan

~~~yaml
terraform_stack: persistent
terraform_apply_enabled: false
terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
terraform_variables: {}
~~~

If Git enables managed KMS creation:

~~~yaml
terraform_variables:
  kms_key_administrators:
    - "arn:aws:iam::<ACCOUNT_ID>:role/<STABLE_KMS_ADMIN_ROLE>"
~~~

Change only `terraform_apply_enabled` to `true` in the fixed Apply JT.

### Platform managed contract

~~~yaml
terraform_stack: platform
terraform_apply_enabled: false
terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
terraform_variables: {}
~~~

Client VPN or external SSM bindings are added to `terraform_variables` only
when the corresponding Git-controlled capability requires them.

### Platform external contract

~~~yaml
terraform_stack: platform
terraform_apply_enabled: false
terraform_persistent_contract_source: external
terraform_external_persistent_resources:
  network_firewall_logging_kms_key_arn: "<EXISTING_KMS_KEY_ARN>"
terraform_variables: {}
~~~

Use an empty external map when CloudWatch Logs default encryption is intended.

### Identity

~~~yaml
terraform_stack: identity
terraform_apply_enabled: false
terraform_variables: {}
~~~

Identity consumes the internally brokered Platform contract and has no
Persistent Resources dependency.

### Recovery managed contract

~~~yaml
terraform_stack: recovery
terraform_apply_enabled: false
terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI_ID>"
~~~

### Recovery external contract

~~~yaml
terraform_stack: recovery
terraform_apply_enabled: false
terraform_persistent_contract_source: external
terraform_external_persistent_resources:
  standard_backup_vault_name: "<EXISTING_STANDARD_VAULT_NAME>"
  air_gapped_backup_vault_arn: "<EXISTING_AIR_GAPPED_VAULT_ARN>"
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI_ID>"
~~~

Vault references are required only when Git enables Recovery backup
integration. External resources are referenced, not imported or managed.

## Destroy Job Templates

Destroy plan for any stack:

~~~yaml
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
~~~

Actual Recovery destroy:

~~~yaml
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY"
~~~

Actual Identity destroy:

~~~yaml
terraform_destroy_enabled: true
terraform_allow_identity_destroy: true
terraform_destroy_confirmation: "DESTROY IDENTITY"
~~~

Actual Platform destroy:

~~~yaml
terraform_destroy_enabled: true
terraform_allow_platform_destroy: true
terraform_destroy_confirmation: "DESTROY PLATFORM"
~~~

Actual Persistent destroy:

~~~yaml
terraform_persistent_contract_source: managed
terraform_destroy_enabled: true
terraform_allow_persistent_destroy: true
terraform_destroy_confirmation: "DESTROY PERSISTENT"
~~~

The Persistent destroy JT is break-glass. External contract mode never runs
the Persistent stack and cannot delete externally owned KMS keys or vaults.

## Workflow order

Managed creation:

~~~text
Persistent -> Platform -> Identity
                       -> Recovery
~~~

External creation:

~~~text
Approved external references -> Platform -> Identity
                                        -> Recovery
~~~

Managed destruction uses reverse dependency order:

~~~text
Recovery -> Identity -> Platform -> Persistent
~~~

Persistent destroy is omitted when resources are external or intentionally
retained. Workflow approval nodes should precede Apply and every actual Destroy
JT.

## RBAC and surveys

- Plan: broad operator access.
- Apply: restricted deployment role plus approval.
- Destroy: privileged operational role plus approval.
- Persistent destroy: most restricted break-glass role.
- Surveys may expose approved AMI selection and temporary exercise intent.
- Surveys must not expose topology, tags, naming, arbitrary Terraform maps,
  stack selection, backend key, security policy, or capability flags.

## Execution Environment

The AAP Execution Environment must contain the repository-approved Terraform
CLI, Ansible dependencies, AWS SDK dependencies, collection content, and
enterprise trust configuration.
