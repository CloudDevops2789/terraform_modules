# AWS models ingress and egress as two distinct resource types, but it is
# friendlier for callers to pass one flat map of rules. These two
# comprehensions split that single map by direction.
#
# The `if` clause is a FILTER: `for k, v in map : k => v if condition`
# keeps only matching entries while preserving their keys, so each rule
# ends up in exactly one of the two maps below.
locals {

  ingress_rules = {
    for key, rule in var.rules :
    key => rule
    if rule.type == "ingress"
  }

  egress_rules = {
    for key, rule in var.rules :
    key => rule
    if rule.type == "egress"
  }

}

# These standalone rule resources are the modern replacement for the
# deprecated aws_security_group_rule. Each resource manages exactly one
# rule, so Terraform can add or remove individual rules without
# rewriting the whole group.
#
# AWS requires exactly one source to be set per rule - a CIDR, a prefix
# list, or another security group. try() resolves each optional attribute
# to null when unset, and the provider ignores null arguments, so the
# caller simply sets whichever one applies.
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = each.value.security_group_id
  description       = try(each.value.description, null)

  ip_protocol = each.value.ip_protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}

# Identical wiring for the egress direction, driven by the filtered
# egress_rules map.
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = each.value.security_group_id
  description       = try(each.value.description, null)

  ip_protocol = each.value.ip_protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}