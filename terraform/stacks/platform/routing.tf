##################################################################################################
# Platform VPC / Transit Gateway Routing
##################################################################################################
#
# Platform owns ordinary VPC route-table routes toward Transit Gateway.
#
# Network Firewall-dependent routing is intentionally NOT owned here.
# The Inspection lifecycle owns:
#
#   - Inspection TGW subnet -> same-AZ Network Firewall endpoint
#   - Network Firewall subnet -> Transit Gateway
#   - source-domain TGW route-table -> Inspection attachment
#
# This keeps Platform topology independently deployable from the optional
# Inspection service lifecycle.
##################################################################################################

locals {
  platform_vpc_routes = merge(
    {},
    [
      for edge_key, edge in var.network_config.connectivity : {
        for route_table_key, route_table in module.vpc[
          edge.source_vpc_key
        ].route_tables :

        "${edge_key}-${route_table_key}" => {
          route_table_id = route_table.id

          destination_cidr_block = module.vpc[
            edge.destination_vpc_key
          ].vpc_cidr

          target = {
            transit_gateway_id = module.transit_gateway.id
          }
        }

        if contains(
          edge.source_route_table_groups,
          route_table.group
        )
      }
    ]...
  )
}

module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = local.platform_vpc_routes

  transit_gateway_routes = {}

  route_table_associations                 = {}
  transit_gateway_route_table_associations = {}
  transit_gateway_route_table_propagations = {}
}
