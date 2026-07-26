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

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id = each.value.security_group_id

  ip_protocol = each.value.ip_protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = each.value.security_group_id

  ip_protocol = each.value.ip_protocol
  from_port   = try(each.value.from_port, null)
  to_port     = try(each.value.to_port, null)

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
}