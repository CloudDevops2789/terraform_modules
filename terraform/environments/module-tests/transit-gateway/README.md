# Purpose

Validates that the `transit-gateway` module (`terraform/modules/transit-gateway`)
deploys successfully: the Transit Gateway itself, a Transit Gateway Route
Table, a VPC attachment, a route table association, and a route table
propagation.

# Module Under Test

`terraform/modules/transit-gateway`

This test exercises gateway creation, one route table, one VPC attachment,
and both the association and propagation resources that wire the
attachment to that route table. It does not attempt to model a multi-VPC,
multi-route-table segmented routing topology - that composition lives in
`sandbox`, not here, because reproducing it would test the topology, not
the module.

# Supporting Resources

- `module.vpc` (`networking.tf`) - the Transit Gateway attachment resource
  the module under test creates requires a real `vpc_id` and real
  `subnet_ids` to attach to; a Transit Gateway cannot exist in isolation.
  One private subnet is the minimum shape that satisfies this. The VPC
  itself is not under test - see the `vpc/` module test for that.

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
destroy - a plain `terraform destroy` removes the Transit Gateway, its
route table, the attachment, and the supporting VPC together.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one Transit
Gateway, one Transit Gateway Route Table, one VPC attachment, one
association, and one propagation. `transit_gateway_id` and
`route_table_ids` are populated outputs.

# Notes

The VPC in this environment exists only to satisfy the Transit Gateway
module's dependency on a real VPC/subnet to attach to. It is not itself
under test - any change to VPC behavior belongs in the `vpc/` module test,
not here.
