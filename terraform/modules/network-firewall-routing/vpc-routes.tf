##################################################################################################
# VPC Routes
##################################################################################################
# Standalone routes provide explicit resource identities and allow Network Firewall endpoint IDs to
# be supplied directly from module outputs on a per-Availability-Zone basis.
resource "aws_route" "this" {
  for_each                    = local.vpc_routes
  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block
  destination_prefix_list_id  = each.value.destination_prefix_list_id
  carrier_gateway_id          = each.value.target.carrier_gateway_id
  core_network_arn            = each.value.target.core_network_arn
  egress_only_gateway_id      = each.value.target.egress_only_gateway_id
  gateway_id                  = each.value.target.gateway_id
  local_gateway_id            = each.value.target.local_gateway_id
  nat_gateway_id              = each.value.target.nat_gateway_id
  network_interface_id        = each.value.target.network_interface_id
  odb_network_arn             = each.value.target.odb_network_arn
  transit_gateway_id          = each.value.target.transit_gateway_id
  vpc_endpoint_id             = each.value.target.vpc_endpoint_id
  vpc_peering_connection_id   = each.value.target.vpc_peering_connection_id
  timeouts {
    create = each.value.timeouts.create
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}
