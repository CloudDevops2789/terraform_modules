# Purpose

Validates that the AWS Backup modules
(`terraform/modules/backup-standard-vault`,
`terraform/modules/backup-logically-air-gapped-vault`,
`terraform/modules/backup-role`, `terraform/modules/backup-plan`, and
`terraform/modules/backup-selection`) deploy successfully. These five
modules are tested together because they are always composed together in
practice - a plan needs a vault, a role, and a selection to be useful, and
sandbox deploys all five together for the same reason.

# Module Under Test

`terraform/modules/backup-standard-vault`,
`terraform/modules/backup-logically-air-gapped-vault`,
`terraform/modules/backup-role`, `terraform/modules/backup-plan`,
`terraform/modules/backup-selection`

This test exercises vault creation (both standard and logically
air-gapped), the IAM role AWS Backup assumes, a plan with a daily schedule
and a copy action into the air-gapped vault, and a selection binding one
real resource to that plan.

# Supporting Resources

- `module.vpc` (`networking.tf`) - gives the supporting EC2 instance
  somewhere to launch. Not under test.
- `module.security_group` (`security.tf`) - gives the supporting EC2
  instance a real security group ID. Not under test.
- `module.ec2` (`compute.tf`) - the `backup-selection` module protects
  existing resources by ARN; it needs at least one real resource to
  reference, and this one instance is it. Not under test.

# Deployment

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

# Destroy

```bash
terraform destroy
```

This environment does not override `force_destroy` on the standard vault
(the module defaults it to `false`), and the logically air-gapped vault
has no such override at all - AWS does not allow deleting an air-gapped
vault that still holds recovery points. On a freshly-applied test,
neither vault has stored anything yet (the daily backup rule runs on its
own schedule, not at apply time), so `terraform destroy` succeeds
cleanly. If you leave this environment running long enough for the daily
rule to fire, empty both vaults before destroying.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one
security group, one EC2 instance, two Backup Vaults, one IAM role, one
Backup Plan, and one Backup Selection. `standard_vault_arn`,
`air_gapped_vault_arn`, `backup_plan_id`, and `backup_selection_id` are
all populated outputs.

# Notes

The VPC, security group, and EC2 instance in this environment exist only
to give the Backup Selection module a real resource ARN to protect. None
of them are themselves under test - changes to their behavior belong in
the `vpc/`, `security-group/`, and `ec2/` module tests. Retention windows
here are shortened relative to sandbox (7/30 days instead of 30/365)
purely to keep this throwaway test cheap to run repeatedly; retention
values are not what this test validates.
