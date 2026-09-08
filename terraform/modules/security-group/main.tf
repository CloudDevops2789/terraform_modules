# One security group per entry of var.security_groups.
#
# Note this resource intentionally declares NO ingress/egress blocks.
# Rules live in the separate security-group-rule module. Mixing inline
# rule blocks with standalone rule resources causes them to fight each
# other on every apply, so a module must pick one approach - this library
# picks standalone rules, which also lets two groups reference each other
# without a circular dependency.
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = coalesce(each.value.name, each.key)
  description = each.value.description
  vpc_id      = each.value.vpc_id

  tags = local.tags[each.key]
}
