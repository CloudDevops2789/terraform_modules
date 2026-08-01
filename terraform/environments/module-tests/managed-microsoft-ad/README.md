# Purpose

Validates that the `managed-microsoft-ad` module
(`terraform/modules/managed-microsoft-ad`) deploys successfully: an AWS
Managed Microsoft AD directory placed into two subnets in two
Availability Zones.

# Module Under Test

`terraform/modules/managed-microsoft-ad`

This test exercises directory creation with the `Standard` edition (the
cheapest option that still proves the module deploys) and the module's
`vpc_settings` wiring against two real subnets.

# Supporting Resources

- `module.vpc` (`networking.tf`) - the module's own variable validation
  requires exactly two subnet IDs in two different Availability Zones;
  this VPC exists solely to provide those two subnets. Not under test.

# Deployment

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set a real managed_ad_password
terraform init
terraform plan
terraform apply
```

AWS Managed Microsoft AD directories typically take 20-45 minutes to
finish provisioning; `terraform apply` will not return until that
completes.

# Destroy

```bash
terraform destroy
```

Directory deletion also takes some time to complete; `terraform destroy`
will not return until AWS confirms the directory is gone.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, two
subnets, and one AWS Managed Microsoft AD directory. `directory_id`,
`dns_ip_addresses`, and `directory_name` are all populated outputs.

# Notes

The VPC in this environment exists only to satisfy the module's
requirement for two subnets in two Availability Zones. It is not itself
under test - changes to VPC behavior belong in the `vpc/` module test.
AWS Managed Microsoft AD has a non-trivial hourly cost even for the
`Standard` edition - destroy this environment promptly after validating
the module.

`managed_ad_password` intentionally uses the same variable name as
`terraform/environments/sandbox`, so it's immediately recognizable to
anyone already familiar with sandbox. Unlike the Client VPN test's
certificates, there is no supporting resource that could generate a
directory password automatically, so this variable has no default and is
always required.
