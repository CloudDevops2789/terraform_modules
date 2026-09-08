# AAP Job Template Design

AAP exposes fixed stack-specific lifecycle entry points:

| Entry point | Purpose |
|---|---|
| `playbooks/terraform/plan/<stack>.yml` | Terraform plan only |
| `playbooks/terraform/apply/<stack>.yml` | Terraform plan followed by approved apply |
| `playbooks/terraform/destroy/<stack>.yml` | Destroy plan, with apply only when explicitly authorized |

The stack and lifecycle operation are encoded in the selected playbook. Fixed
stack-specific Job Templates (JTs) provide clear RBAC, audit history,
troubleshooting, and protection from selecting the wrong stack or operation at
launch. The reusable execution engines under `playbooks/terraform/common/` are
implementation details and are not selected directly by AAP Job Templates.

## Environment inventory

Create one Git-controlled, SCM-sourced AAP inventory for each deployment
environment and contract profile. The customer-neutral structure is under
`inventories/example/`.

The selected inventory supplies:

~~~yaml
terraform_environment: sandbox

assume_role_role_arn: "<APPROVED_TERRAFORM_ROLE_ARN>"
assume_role_aws_region: "<DEPLOYMENT_REGION>"
assume_role_application_name: "ire-terraform"
assume_role_expected_account_id: "<12_DIGIT_ACCOUNT_ID>"

terraform_backend_bucket: "<APPROVED_STATE_BUCKET>"
terraform_backend_region: "<BACKEND_BUCKET_REGION>"

terraform_persistent_contract_source: managed
terraform_external_persistent_resources: {}
~~~

Store real environment values only in the private deployment-configuration
repository. Do not duplicate these values in individual JTs.

For an environment that consumes existing Persistent Resources, use a separate
approved inventory profile:

~~~yaml
terraform_persistent_contract_source: external
terraform_external_persistent_resources:
  network_firewall_logging_kms_key_arn: "<EXISTING_KMS_KEY_ARN>"
  standard_backup_vault_name: "<EXISTING_STANDARD_VAULT_NAME>"
  air_gapped_backup_vault_arn: "<EXISTING_AIR_GAPPED_VAULT_ARN>"
~~~

Unused external references may be omitted. Never run the Persistent stack JTs
with an external contract inventory because those resources are not managed by
this Terraform state.

## Recommended fixed Job Templates

Create four JTs per lifecycle stack. This gives 20 predictable templates
backed by fixed stack-specific lifecycle entry points and one shared environment
inventory.

| Stack | Plan | Apply | Destroy plan | Destroy |
|---|---|---|---|---|
| Persistent | `IRE-Persistent-Plan` | `IRE-Persistent-Apply` | `IRE-Persistent-Destroy-Plan` | `IRE-Persistent-Destroy` |
| Platform | `IRE-Platform-Plan` | `IRE-Platform-Apply` | `IRE-Platform-Destroy-Plan` | `IRE-Platform-Destroy` |
| Identity | `IRE-Identity-Plan` | `IRE-Identity-Apply` | `IRE-Identity-Destroy-Plan` | `IRE-Identity-Destroy` |
| Remote Access | `IRE-Remote-Access-Plan` | `IRE-Remote-Access-Apply` | `IRE-Remote-Access-Destroy-Plan` | `IRE-Remote-Access-Destroy` |
| Recovery | `IRE-Recovery-Plan` | `IRE-Recovery-Apply` | `IRE-Recovery-Destroy-Plan` | `IRE-Recovery-Destroy` |

Every JT selects the approved SCM inventory. Do not expose
`terraform_environment`, `terraform_stack`, lifecycle enablement, backend
configuration, account identity, or contract source as free-form survey
variables.

## Plan and Apply Job Template variables

Plan and Apply Job Templates select different SCM playbook entry points rather
than changing a lifecycle flag.

For example:

~~~text
IRE-Persistent-Plan
  -> playbooks/terraform/plan/persistent.yml

IRE-Persistent-Apply
  -> playbooks/terraform/apply/persistent.yml

IRE-Platform-Plan
  -> playbooks/terraform/plan/platform.yml

IRE-Platform-Apply
  -> playbooks/terraform/apply/platform.yml
~~~

Do not define `terraform_stack` or `terraform_apply_enabled` in Job Template
variables. The selected entry point fixes both the stack and the operation.

Runtime Terraform inputs remain narrow and allowlisted. Use an empty map when a
stack requires no runtime values:

~~~yaml
terraform_variables: {}
~~~

When Git enables managed logging-KMS creation, Persistent Plan and Apply supply
the same approved administrator binding:

~~~yaml
terraform_variables:
  kms_key_administrators:
    - "arn:aws:iam::<ACCOUNT_ID>:role/<STABLE_KMS_ADMIN_ROLE>"
~~~

When `managed_ad_enabled = false`, Identity uses:

~~~yaml
terraform_variables: {}
~~~

Before Git enables Managed AD, create an approved custom credential type with a
secret input field:

~~~yaml
fields:
  - id: managed_ad_password
    type: string
    label: Managed AD bootstrap password
    secret: true
required:
  - managed_ad_password
~~~

Use this injector configuration:

~~~yaml
env:
  IRE_TERRAFORM_MANAGED_AD_PASSWORD: "{{ managed_ad_password }}"
~~~

Attach an instance of this credential type to the fixed Identity Plan, Apply,
and Destroy Job Templates. Keep `terraform_variables: {}` in those templates;
the password is resolved separately by the playbooks under `no_log`.

Do not place the password or the injected environment variable value in Job
Template YAML, surveys, inventory, SCM, or shell commands.

Remote Access Plan and Apply run only after Platform, Identity and the Managed
AD user/group bootstrap workflow. Git controls enablement and authentication
mode. AAP supplies only the approved runtime bindings required by that mode:

~~~yaml
terraform_variables:
  client_vpn_access_group_id: "<MANAGED_AD_VPN_GROUP_SID>"
  server_certificate_arn: "<APPROVED_ACM_SERVER_CERTIFICATE_ARN>"
~~~

Future `directory_and_mutual` mode additionally supplies:

~~~yaml
terraform_variables:
  client_vpn_access_group_id: "<MANAGED_AD_VPN_GROUP_SID>"
  server_certificate_arn: "<APPROVED_ACM_SERVER_CERTIFICATE_ARN>"
  client_root_certificate_chain_arn: "<APPROVED_ACM_CLIENT_ROOT_CA_ARN>"
~~~

Recovery Plan and Apply use the reviewed Git configuration plus only approved
runtime exercise intent when required:

~~~yaml
terraform_variables:
  demo_ec2_enabled: true
~~~

The reviewed `recovery.tfvars` file owns each workload's AMI, access method,
placement, security groups, backup intent, and optional SSH key-pair reference.
Use an empty runtime map when temporary Recovery compute is not required.

## Managed AD Client VPN user provisioning

Use `playbooks/managed_ad_client_vpn_users.yml` after Identity and before Remote
Access. Supply a reviewed list of SAM account names and one authorization group:

~~~yaml
managed_ad_directory_name: "<APPROVED_DIRECTORY_FQDN>"
managed_ad_client_vpn_group_name: "IRE-Client-VPN-Users"
managed_ad_client_vpn_user_names:
  - user001
  - user002
managed_ad_reset_existing_user_passwords: false
~~~

Create a secret AAP credential whose injector is:

~~~yaml
env:
  IRE_MANAGED_AD_USER_BOOTSTRAP_PASSWORD: "{{ managed_ad_user_bootstrap_password }}"
~~~

One credential supplies the shared bootstrap password for the whole controlled
batch; do not create one AAP credential per AD user.

The workflow creates only missing users, sets the password only for newly
created users, adds users to the VPN group and publishes its SID. Removing a
name from the input list does not delete or disable an AD account. Normal
offboarding requires a separate approved identity process.

A shared bootstrap password is suitable only for a controlled initial rollout.
Directory Service Data password reset does not provide this workflow with a
reliable force-change-at-next-VPN-login control, and Client VPN is not a
password-enrollment interface. Enterprise onboarding should therefore replace
the shared password promptly through an approved individual password or
self-service identity process before broad access is granted.

## Destroy Job Template variables

Destroy-plan and Destroy Job Templates use the same stack-specific destroy
entry point. The difference is whether destructive execution is explicitly
enabled.

For example, Platform Destroy Plan and Platform Destroy both select:

~~~text
playbooks/terraform/destroy/platform.yml
~~~

A destroy-plan JT keeps execution disabled:

~~~yaml
terraform_variables: {}
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
~~~

An actual destroy requires explicit enablement and the exact stack confirmation:

~~~yaml
terraform_variables: {}
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY PLATFORM"
~~~

The expected confirmation is defined by the stack configuration under
`playbooks/terraform/config/<stack>.yml`.

The current confirmations are:

~~~text
Persistent    DESTROY PERSISTENT
Platform      DESTROY PLATFORM
Identity      DESTROY IDENTITY
Remote Access DESTROY REMOTE ACCESS
Recovery      DESTROY RECOVERY
~~~

Do not define `terraform_stack` or legacy per-stack destroy flags such as
`terraform_allow_platform_destroy` in Job Templates. Stack identity comes from
the selected playbook, and destroy authorization is enforced by
`terraform_destroy_enabled` plus the exact stack confirmation.

Supply the same allowlisted runtime bindings used by the matching Plan and Apply
Job Templates so Terraform evaluates the same configuration. For example,
Remote Access destroy may require:

~~~yaml
terraform_variables:
  client_vpn_access_group_id: "<MANAGED_AD_VPN_GROUP_SID>"
  server_certificate_arn: "<APPROVED_ACM_SERVER_CERTIFICATE_ARN>"
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY REMOTE ACCESS"
~~~

Persistent destroy is break-glass. External contract mode never runs the
Persistent stack and cannot delete externally owned KMS keys or Backup vaults.

## Workflow order

Managed creation:

~~~text
Persistent -> Platform -> Identity -> AD bootstrap -> Remote Access
                       -> Recovery
~~~

External creation:

~~~text
Approved external references -> Platform -> Identity
                                        -> Recovery
~~~

Managed destruction uses reverse dependency order:

~~~text
Recovery -> Remote Access -> Identity -> Platform -> Persistent
~~~

Persistent destroy is omitted when resources are external or intentionally
retained. Workflow approval nodes should precede Apply and every actual Destroy
JT. Keep the atomic JTs available for controlled troubleshooting.

## RBAC and surveys

- Plan: broad operator access.
- Apply: restricted deployment role plus approval.
- Destroy: privileged operational role plus approval.
- Persistent destroy: most restricted break-glass role.
- Surveys may expose temporary exercise lifecycle intent.
- Surveys must not expose topology, tags, naming, arbitrary Terraform maps,
  stack selection, backend configuration, security policy, capability flags,
  target account, or lifecycle enablement.

## Execution Environment

The AAP Execution Environment contains the repository-approved Terraform CLI,
Ansible dependencies, AWS SDK dependencies, collection content, and enterprise
trust configuration. It must not contain environment-specific infrastructure
bindings.
