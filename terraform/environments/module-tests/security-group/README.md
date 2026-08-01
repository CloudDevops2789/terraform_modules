# Purpose

Validates that the `security-group` and `security-group-rule` modules
(`terraform/modules/security-group`, `terraform/modules/security-group-rule`)
deploy successfully. The two are tested together because a rule cannot
exist without a group to attach it to - they are always deployed as a
pair, in sandbox as much as here.

# Module Under Test

`terraform/modules/security-group` and `terraform/modules/security-group-rule`

This test exercises group creation, the rule module's ingress/egress split,
and both the `aws_vpc_security_group_ingress_rule` and
`aws_vpc_security_group_egress_rule` resource types it manages.

# Supporting Resources

- `module.vpc` (`networking.tf`) - a security group must belong to a real
  VPC; `aws_security_group` requires a real `vpc_id`. One private subnet
  is the minimum shape needed (the subnet itself is unused by this test,
  but the vpc module requires at least one). Not under test.

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
destroy - a plain `terraform destroy` removes the rules, the group, and
the supporting VPC together.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one subnet,
one security group, and two security group rules (one ingress, one
egress). `security_group_ids` is a populated output.

# Notes

The VPC in this environment exists only to satisfy the security-group
module's dependency on a real `vpc_id`. It is not itself under test -
changes to VPC behavior belong in the `vpc/` module test.
