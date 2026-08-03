##################################################################################################
# AWS Network Firewalls
##################################################################################################
# The same resource supports VPC-attached and Transit Gateway-attached deployment models. Input
# validation guarantees that only the attachment-specific blocks for the selected model are rendered.
resource "aws_networkfirewall_firewall" "this" {
  for_each                            = local.firewalls
  availability_zone_change_protection = each.value.availability_zone_change_protection
  delete_protection                   = each.value.delete_protection
  description                         = each.value.description
  enabled_analysis_types              = each.value.enabled_analysis_types
  firewall_policy_arn                 = each.value.firewall_policy_arn
  firewall_policy_change_protection   = each.value.firewall_policy_change_protection
  name                                = each.value.name
  subnet_change_protection            = each.value.subnet_change_protection
  transit_gateway_id                  = each.value.transit_gateway_id
  vpc_id                              = each.value.vpc_id
  dynamic "availability_zone_mapping" {
    for_each = each.value.availability_zone_mappings
    content {
      availability_zone_id = availability_zone_mapping.value.availability_zone_id
    }
  }
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      key_id = encryption_configuration.value.key_id
      type   = encryption_configuration.value.type
    }
  }
  dynamic "subnet_mapping" {
    for_each = each.value.subnet_mappings
    content {
      ip_address_type = subnet_mapping.value.ip_address_type
      subnet_id       = subnet_mapping.value.subnet_id
    }
  }
  tags = each.value.tags
  timeouts {
    create = each.value.timeouts.create
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}
