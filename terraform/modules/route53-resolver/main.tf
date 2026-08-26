##################################################################################################
# Route 53 Resolver endpoint, forwarding rules, and VPC associations
##################################################################################################

resource "aws_route53_resolver_endpoint" "this" {
  name                   = var.name
  direction              = var.direction
  resolver_endpoint_type = var.resolver_endpoint_type
  protocols              = var.protocols

  security_group_ids = var.security_group_ids

  dynamic "ip_address" {
    for_each = toset(var.subnet_ids)

    content {
      subnet_id = ip_address.value
    }
  }

  tags = var.tags
}

resource "aws_route53_resolver_rule" "this" {
  for_each = var.forwarding_rules

  name                 = coalesce(each.value.name, each.key)
  domain_name          = each.value.domain_name
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.this.id

  dynamic "target_ip" {
    for_each = each.value.target_ips

    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = merge(var.tags, each.value.tags)
}

locals {
  rule_associations = merge(
    {},
    [
      for rule_key, rule in var.forwarding_rules : {
        for vpc_key, vpc_id in rule.vpc_ids :
        "${rule_key}/${vpc_key}" => {
          rule_key = rule_key
          vpc_key  = vpc_key
          vpc_id   = vpc_id
        }
      }
    ]...
  )
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each = local.rule_associations

  resolver_rule_id = aws_route53_resolver_rule.this[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  for_each = var.query_log_config_id == null ? {} : var.query_log_vpc_ids

  resolver_query_log_config_id = var.query_log_config_id
  resource_id                  = each.value
}
