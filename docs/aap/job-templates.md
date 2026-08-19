# AAP Job Template Design

AAP uses two reusable lifecycle playbooks:

| Playbook | Purpose |
|---|---|
| `playbooks/terraform_deploy.yml` | Terraform plan and approved apply |
| `playbooks/terraform_destroy.yml` | Destroy plan and explicitly authorized destroy |

Keep the deploy and destroy playbooks separate. Fixed stack-specific Job
Templates (JTs) provide clear RBAC, audit history, troubleshooting, and
protection from selecting the wrong stack at launch.

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

Create four JTs per stack. This gives 16 predictable templates backed by the
two reusable playbooks and one shared environment inventory.

| Stack | Plan | Apply | Destroy plan | Destroy |
|---|---|---|---|---|
| Persistent | `IRE-Persistent-Plan` | `IRE-Persistent-Apply` | `IRE-Persistent-Destroy-Plan` | `IRE-Persistent-Destroy` |
| Platform | `IRE-Platform-Plan` | `IRE-Platform-Apply` | `IRE-Platform-Destroy-Plan` | `IRE-Platform-Destroy` |
| Identity | `IRE-Identity-Plan` | `IRE-Identity-Apply` | `IRE-Identity-Destroy-Plan` | `IRE-Identity-Destroy` |
| Recovery | `IRE-Recovery-Plan` | `IRE-Recovery-Apply` | `IRE-Recovery-Destroy-Plan` | `IRE-Recovery-Destroy` |

Every JT selects the approved SCM inventory. Do not expose
`terraform_environment`, `terraform_stack`, lifecycle enablement, backend
configuration, account identity, or contract source as free-form survey
variables.

## Deploy Job Template variables

Persistent plan:

~~~yaml
terraform_stack: persistent
terraform_apply_enabled: false
terraform_variables: {}
~~~

Persistent apply changes only the fixed lifecycle flag:

~~~yaml
terraform_stack: persistent
terraform_apply_enabled: true
terraform_variables: {}
~~~

When Git enables managed logging-KMS creation, both Persistent JTs supply the
same approved administrator binding:

~~~yaml
terraform_variables:
  kms_key_administrators:
    - "arn:aws:iam::<ACCOUNT_ID>:role/<STABLE_KMS_ADMIN_ROLE>"
~~~

Platform plan:

~~~yaml
terraform_stack: platform
terraform_apply_enabled: false
terraform_variables: {}
~~~

Platform apply:

~~~yaml
terraform_stack: platform
terraform_apply_enabled: true
terraform_variables: {}
~~~

Git controls Client VPN enablement and authentication type. When required by
that reviewed configuration, both Platform JTs receive the same approved
external bindings under `terraform_variables`:

~~~yaml
terraform_variables:
  server_certificate_arn: "<APPROVED_SERVER_CERTIFICATE_ARN>"
  root_certificate_chain_arn: "<APPROVED_ROOT_CA_CERTIFICATE_ARN>"
~~~

Use `saml_provider_arn` instead of `root_certificate_chain_arn` when the
Git-selected authentication type is federated.

Identity plan and apply use:

~~~yaml
terraform_stack: identity
terraform_apply_enabled: false  # true only in the fixed Apply JT
terraform_variables: {}
~~~

Recovery plan and apply use:

~~~yaml
terraform_stack: recovery
terraform_apply_enabled: false  # true only in the fixed Apply JT
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI_ID>"
~~~

Use an empty map when the temporary Recovery workload is disabled in Git.

## Destroy Job Template variables

Every destroy-plan JT uses:

~~~yaml
terraform_stack: "<fixed-stack>"
terraform_variables: {}
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
~~~

Supply the same allowlisted runtime bindings used by the matching deploy JTs so
Terraform evaluates the same configuration.

Actual Recovery destroy:

~~~yaml
terraform_stack: recovery
terraform_variables: {}
terraform_destroy_enabled: true
terraform_allow_recovery_destroy: true
terraform_destroy_confirmation: "DESTROY RECOVERY"
~~~

Actual Identity destroy:

~~~yaml
terraform_stack: identity
terraform_variables: {}
terraform_destroy_enabled: true
terraform_allow_identity_destroy: true
terraform_destroy_confirmation: "DESTROY IDENTITY"
~~~

Actual Platform destroy:

~~~yaml
terraform_stack: platform
terraform_variables: {}
terraform_destroy_enabled: true
terraform_allow_platform_destroy: true
terraform_destroy_confirmation: "DESTROY PLATFORM"
~~~

Actual Persistent destroy:

~~~yaml
terraform_stack: persistent
terraform_variables: {}
terraform_destroy_enabled: true
terraform_allow_persistent_destroy: true
terraform_destroy_confirmation: "DESTROY PERSISTENT"
~~~

Persistent destroy is break-glass. External contract mode never runs the
Persistent stack and cannot delete externally owned KMS keys or vaults.

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
JT. Keep the atomic JTs available for controlled troubleshooting.

## RBAC and surveys

- Plan: broad operator access.
- Apply: restricted deployment role plus approval.
- Destroy: privileged operational role plus approval.
- Persistent destroy: most restricted break-glass role.
- Surveys may expose approved AMI selection and temporary exercise intent.
- Surveys must not expose topology, tags, naming, arbitrary Terraform maps,
  stack selection, backend configuration, security policy, capability flags,
  target account, or lifecycle enablement.

## Execution Environment

The AAP Execution Environment contains the repository-approved Terraform CLI,
Ansible dependencies, AWS SDK dependencies, collection content, and enterprise
trust configuration. It must not contain environment-specific infrastructure
bindings.
