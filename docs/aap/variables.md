# AAP Runtime Variable Contract

This document defines the runtime input contract between Ansible Automation Platform (AAP), the Terraform orchestration playbooks, and the integrated IRE Terraform environment.

## Input ownership model

| Class | Typical owner | Examples |
|---|---|---|
| Platform configuration | AAP platform team / environment definition | execution role, backend location, Terraform root |
| Environment configuration | IRE engineering / approved configuration | Region, naming, CIDRs, AMI, authentication mode |
| Secrets | AAP Credential / enterprise secret manager | directory-service passwords and other secrets |
| Workflow controls | AAP Workflow | apply and destroy authorization |

## Orchestration variables

| Variable | Required | Sensitive | Recommended source | Purpose |
|---|---:|---:|---|---|
| `assume_role_role_arn` | Yes | No | Job Template / environment mapping | IAM role assumed before Terraform execution |
| `assume_role_expected_account_id` | Recommended | No | Job Template / environment mapping | Expected AWS account ID used to validate the assumed identity before Terraform execution |
| `assume_role_aws_region` | Yes | No | Job Template | Region used by AWS AssumeRole tasks |
| `assume_role_application_name` | No | No | Job Template | Audit-friendly AssumeRole session naming |
| `terraform_environment` | Yes | No | Job Template | Approved Terraform environment root |
| `terraform_backend_bucket` | Yes | No | Environment mapping | S3 remote-state bucket |
| `terraform_backend_key` | Yes | No | Environment mapping | Environment-specific state object key |
| `terraform_backend_region` | Yes | No | Environment mapping | Backend Region |
| `terraform_apply_enabled` | No | No | Workflow control | Enables application of the saved deployment plan |
| `terraform_destroy_enabled` | No | No | Workflow control | Enables application of the saved destroy plan |
| `terraform_destroy_confirmation` | No | No | Workflow control | Additional destructive-action confirmation |
| `terraform_public_key` | Yes for current environment interface | No | Credential / approved variable | Public SSH key material materialized temporarily for Terraform |
| `terraform_variables` | Yes | Mixed | Environment config + secret injection | Map passed to the Terraform environment root |

## Terraform variable map

`terraform_variables` contains inputs consumed by the integrated Terraform environment.

### Core environment inputs

| Variable | Sensitive | Purpose |
|---|---:|---|
| `aws_region` | No | AWS Region |
| `ami_id` | No | Approved AMI used by applicable EC2 resources |
| `naming` | No | Portable naming components |
| `resource_name_overrides` | No | Optional exact approved AWS resource names |
| `network_config` | No | IRE account, Client VPN, VPC, and subnet CIDR allocation |
| `network_inspection_mode` | No | `firewall` or `bypass` routing behavior |

### Client VPN inputs

| Variable | Sensitive | Purpose |
|---|---:|---|
| `authentication_type` | No | `certificate` or `federated` |
| `server_certificate_arn` | No | ACM server certificate ARN |
| `root_certificate_chain_arn` | No | Root CA ARN for certificate authentication |
| `saml_provider_arn` | No | Existing IAM SAML provider ARN for federated authentication |
| `manage_saml_provider` | No | Selects existing-provider or Terraform-managed-provider ownership |
| `saml_provider_name` | No | Optional approved name for a Terraform-managed IAM SAML provider |
| `saml_metadata_document` | No | Approved SAML metadata supplied at runtime when Terraform manages the provider |

Federated authentication can consume an existing IAM SAML provider or create the AWS-side IAM SAML provider through the environment composition.

MFA is enforced by the approved enterprise identity provider and is not a Terraform Client VPN boolean.

### Organization metadata

The integrated environment currently exposes organization metadata through `org_*` variables, including:

- `org_it_cost_center`;
- `org_department`;
- `org_cmdb_calculated_app`;
- `org_business_criticality`;
- `org_environment`;
- `org_data_classification`;
- `org_project_name`;
- `org_managed_by`;
- `org_additional_tags`.

### Security policy

The current integrated environment also consumes:

- `security_group_rules`;
- `network_firewall_rules`.

These are maintained as version-controlled policy in `terraform/environments/sandbox/network-policy.auto.tfvars` so that trust-policy changes remain reviewable in Git.

### Sensitive Terraform inputs

Sensitive Terraform values, including directory-service passwords, must be injected through approved AAP Credentials or enterprise secret-management integrations.

They are intentionally omitted from the tracked example runtime file.

## Control-variable guidance

The following variables should not be exposed as unrestricted survey inputs in production:

```text
terraform_apply_enabled
terraform_destroy_enabled
terraform_destroy_confirmation
```

Recommended production pattern:

```text
Plan Job
   ↓
AAP Approval
   ↓
Deploy Job
   └── internally enables apply
```

and:

```text
Destroy Plan Job
   ↓
AAP Approval
   ↓
Destroy Job
   └── internally enables destroy and confirmation
```

## Example

See:

[`examples/terraform-job-vars.example.yml`](examples/terraform-job-vars.example.yml)
