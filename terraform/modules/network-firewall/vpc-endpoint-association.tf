##################################################################################################
# Additional VPC Endpoint Associations
##################################################################################################
# A VPC endpoint association can reference a firewall created in this module by logical key or a
# firewall owned elsewhere by direct ARN. AWS permits these associations only for VPC-attached
# firewalls and only in Availability Zones where the primary firewall already has an endpoint.
resource "aws_networkfirewall_vpc_endpoint_association" "this" {
  for_each    = local.vpc_endpoint_associations
  description = each.value.description
  firewall_arn = each.value.firewall_key != null ? try(
    aws_networkfirewall_firewall.this[each.value.firewall_key].arn,
    "invalid-firewall-key"
  ) : each.value.firewall_arn
  vpc_id = each.value.vpc_id
  subnet_mapping {
    ip_address_type = each.value.subnet_mapping.ip_address_type
    subnet_id       = each.value.subnet_mapping.subnet_id
  }
  tags = each.value.tags
  timeouts {
    create = each.value.timeouts.create
    delete = each.value.timeouts.delete
  }
  lifecycle {
    precondition {
      condition = each.value.firewall_key == null || contains(
        keys(local.firewalls),
        each.value.firewall_key
      )
      error_message = "firewall_key must reference a key present in var.firewalls."
    }
    precondition {
      condition = each.value.firewall_key == null || try(
        local.firewalls[each.value.firewall_key].vpc_id != null,
        false
      )
      error_message = "VPC endpoint associations can reference only VPC-attached firewalls, not Transit Gateway-attached firewalls."
    }
  }
}
