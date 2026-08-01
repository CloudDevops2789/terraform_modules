# Purpose

Validates that the `vpc` module (`terraform/modules/vpc`) deploys
successfully: a VPC, a private subnet, a private route table, and the
route table association between them.

# Module Under Test

`terraform/modules/vpc`

This test exercises the module's required inputs (`vpc_name`, `cidr_block`,
`availability_zone_count`, `private_subnets`) and the always-on private
networking path (VPC, private subnet, private route table, association).
The optional public-subnet / Internet Gateway path is intentionally not
exercised here, since validating "does this module deploy" does not require
every optional code path to run.

# Supporting Resources

None. The vpc module has no dependencies on anything outside itself - it
only reads AWS's own Availability Zone list via a data source. Everything
this environment creates (`module.vpc`) is the module under test.

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

Nothing in this environment has a retention/lock that would block
destroy - a plain `terraform destroy` removes everything it created.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one subnet,
one route table, and one route table association. `vpc_id`,
`vpc_cidr`, and `private_subnet_ids` are all populated outputs.

# Notes

This environment has no supporting resources - the vpc module is
self-contained. Everything created here is the module under test itself,
so there is nothing to distinguish from "not under test" in this case.
