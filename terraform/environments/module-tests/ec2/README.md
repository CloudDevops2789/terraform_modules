# Purpose

Validates that the `ec2` module (`terraform/modules/ec2`) deploys
successfully: one instance created via the module's `for_each` over
`var.instances`.

# Module Under Test

`terraform/modules/ec2`

This test exercises instance creation, the module's tag-merging locals, and
its handling of unset optional attributes (`key_name`,
`iam_instance_profile`, `private_ip`, `root_block_device`), all of which
resolve to their documented defaults.

# Supporting Resources

- `module.vpc` (`networking.tf`) - `aws_instance` requires a real
  `subnet_id` to launch into; the ec2 module does not create networking
  itself. One private subnet is the minimum shape needed. Not under test.
- `module.security_group` (`security.tf`) - `aws_instance` requires a real
  security group ID. No explicit rules are configured because AWS attaches
  its own default allow-all egress rule automatically, and rule behavior
  is validated by the `security-group/` module test, not here. Not under
  test.

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
destroy - a plain `terraform destroy` removes the instance, the security
group, and the supporting VPC together.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one subnet,
one security group, and one EC2 instance. `instance_ids` and `private_ips`
are populated outputs.

# Notes

The VPC and security group in this environment exist only to satisfy the
EC2 module's dependency on a real subnet and security group ID. Neither is
itself under test - changes to networking or security group behavior
belong in the `vpc/` and `security-group/` module tests.
