# IRE Persistent Foundation

This Terraform environment owns long-lived IRE security and recovery
resources.

These resources intentionally survive deployment and destruction of
the disposable recovery environment.

## Resources Owned

Foundation currently owns:

- Standard AWS Backup vault
- Logically air-gapped AWS Backup vault
- Customer-managed KMS key for Network Firewall CloudWatch logs

Reusable modules remain under `terraform/modules`.

## Disposable Resources

Foundation does not own:

- VPCs
- Subnets
- Transit Gateway resources
- EC2 recovery instances
- Client VPN
- Security groups
- Backup plans
- Backup selections
- Temporary recovery workloads

Those resources remain under the `sandbox` environment.

## State Boundary

Foundation must use a different Terraform backend state key from
Sandbox.

Example:

    bucket       = "replace-with-approved-state-bucket"
    key          = "foundation/terraform.tfstate"
    region       = "replace-with-approved-region"
    encrypt      = true
    use_lockfile = true

Do not use the same state object for Foundation and Sandbox.

## KMS Administration

kms_key_administrators must contain stable IAM principal ARNs.

Use an approved IAM role ARN such as:

    kms_key_administrators = [
      "arn:aws:iam::123456789012:role/approved-terraform-role"
    ]

Do not use temporary STS assumed-role session ARNs.

## Sandbox Integration

Foundation exports:

- standard_backup_vault_name
- standard_backup_vault_arn
- air_gapped_backup_vault_name
- air_gapped_backup_vault_arn
- network_firewall_logging_kms_key_arn

Sandbox consumes the approved values through foundation_resources.

Terraform remote state is intentionally not required.

## AAP Deployment

The generic Terraform deployment playbook can target Foundation using:

    terraform_environment: foundation

Foundation requires:

- its own backend key
- its own terraform_variables payload
- the approved Terraform execution role

Foundation does not require an SSH public key because it creates no
EC2 instances.

## Destruction

The generic recovery-environment destroy workflow rejects:

    terraform_environment: foundation

Foundation resources are intentionally persistent.

Deleting Foundation resources requires a separate governed process.

## Existing Enterprise Resources

If approved vaults or KMS keys already exist, do not rename them simply
to allow Terraform to create replacements.

Preferred onboarding process:

1. Validate the existing resource.
2. Confirm its configuration.
3. Import it into Foundation state through an approved migration.
4. Run Terraform plan.
5. Reconcile only intentional differences.

Do not remove resources from Terraform state merely to bypass lifecycle
or organization controls.

## Validation

Run:

    terraform -chdir=terraform/environments/foundation init -backend=false
    terraform -chdir=terraform/environments/foundation validate
