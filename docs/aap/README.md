# AAP Orchestration Guide

This document defines the Ansible Automation Platform (AAP) operating model for the AWS Isolated Recovery Environment (IRE).

Terraform remains the infrastructure provisioning engine. AAP provides authentication, orchestration, runtime configuration, execution control, and approval integration.

> [!IMPORTANT]
> The current playbooks provide guarded plan/apply and destroy behavior. Production AAP workflow approvals and standardized Execution Environment packaging are separate platform-integration controls.

## Execution model

```text
AAP Project Sync
      ↓
Approved AWS execution context
      ↓
ire_platform.aws.assume_role
      ↓
Temporary STS credentials
      ↓
Terraform backend initialization
      ↓
Terraform validation
      ↓
Terraform plan
      ↓
Approval / execution control
      ↓
Terraform apply
      ↓
Temporary-artifact cleanup
```

## Repository components

| Component | Purpose |
|---|---|
| `playbooks/terraform_backend_bucket.yml` | Bootstrap persistent Terraform remote-state storage |
| `playbooks/terraform_deploy.yml` | Validate, plan, and conditionally apply Terraform |
| `playbooks/terraform_destroy.yml` | Validate, create a destroy plan, and conditionally destroy |
| `playbooks/test_assume_role.yml` | Validate AWS role assumption |
| `playbooks/test_caller_identity.yml` | Validate the effective AWS caller identity |
| `ire_platform.aws.assume_role` | Assume the approved AWS IAM role and publish temporary STS credentials |

## Deployment workflow

The deployment playbook performs:

1. validation of required execution inputs;
2. validation of the selected Terraform environment root;
3. AWS IAM role assumption;
4. temporary workspace creation;
5. temporary public-key materialization for the current Terraform interface;
6. runtime `.auto.tfvars.json` generation;
7. `terraform init`;
8. `terraform validate`;
9. saved Terraform plan generation;
10. plan-summary reporting;
11. conditional saved-plan application; and
12. cleanup in an Ansible `always` block.

The default control is:

```yaml
terraform_apply_enabled: false
```

With the default value, the workflow stops after a successful plan.

## Destroy workflow

Destroy uses a separate playbook and separate controls.

Safe defaults:

```yaml
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
```

Execution requires both:

```yaml
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY"
```

The playbook creates a saved `terraform plan -destroy` plan before any destructive execution.

> [!WARNING]
> Production AAP should add workflow-level approval controls in addition to the playbook-level destroy guard.

## Runtime configuration

AAP runtime inputs are divided into four control planes:

### Job Template configuration

Values normally owned by the platform or environment definition:

- approved AWS role ARN;
- AWS Region;
- approved Terraform environment root;
- Terraform backend bucket;
- Terraform backend state key;
- Terraform backend Region.

### Environment configuration

Non-secret Terraform values such as:

- naming;
- network allocation;
- approved AMI;
- Client VPN authentication mode;
- certificate ARNs;
- SAML provider ownership mode;
- existing SAML provider ARN where applicable;
- approved SAML provider metadata where Terraform manages the AWS-side provider;
- organization tagging metadata.

### Credential / secret integration

Sensitive inputs should be injected through AAP Credentials or an approved enterprise secret-management integration, including:

- directory-service passwords;
- bootstrap credentials where applicable;
- other environment secrets.

### Workflow controls

Execution controls should be owned by the AAP workflow rather than exposed as casual operator inputs:

- `terraform_apply_enabled`;
- `terraform_destroy_enabled`;
- `terraform_destroy_confirmation`.

## Temporary artifacts

The orchestration workflow can create:

- a temporary public SSH key file;
- a temporary `.auto.tfvars.json` file;
- a saved deployment plan;
- a saved destroy plan.

The temporary execution directory is removed after execution.

Terraform plan files can contain sensitive values and must not be retained or committed.

## Remote state

Remote-state bootstrap is separated from normal IRE deployment and destroy operations.

The Terraform root uses a minimal backend declaration:

```hcl
terraform {
  backend "s3" {}
}
```

Backend values are supplied at runtime.

Destroying the IRE environment must not implicitly remove its Terraform backend.

## Production AAP controls

The production AAP implementation should include:

- Project synchronization from the approved Git repository;
- standardized Execution Environment;
- controlled Job Templates;
- AAP credentials or secret-manager integration;
- workflow-level approval before deployment;
- workflow-level approval before destruction;
- AWS account and role assertions;
- environment-to-backend mapping validation;
- post-deployment infrastructure validation.

## Execution Environment requirements

The standardized AAP Execution Environment should provide:

- repository-approved Ansible Core version;
- `amazon.aws`;
- the `ire_platform.aws` collection;
- `boto3` and `botocore`;
- repository-approved Terraform CLI version;
- required Python dependencies;
- required enterprise CA certificates and trust configuration.

The Execution Environment should be versioned and promoted through the approved enterprise image-management process.

## Related documents

- [`variables.md`](variables.md)
- [`examples/terraform-job-vars.example.yml`](examples/terraform-job-vars.example.yml)
- [`../terraform/configuration-reference.md`](../terraform/configuration-reference.md)
