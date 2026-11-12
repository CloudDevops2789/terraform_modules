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

  ################################################################################################
  # External Transit Gateway Peer - VPC Routes
  ################################################################################################
  #
  # Approved VPC route-table groups receive routes for the configured remote
  # enterprise CIDRs through the IRE Transit Gateway.
  #
  # These routes only move traffic from the source VPC into the TGW. Firewall-
  # dependent forwarding from the TGW remains owned by the Inspection stack.
  ################################################################################################

  external_peer_vpc_routes = merge(
    {},
    [
      for vpc_key, external_config
      in var.network_config.transit_gateway_peering.ire_to_external :

      merge(
        {},
        [
          for remote_cidr
          in var.network_config.transit_gateway_peering.remote_cidrs : {

            for route_table_key, route_table
            in module.vpc[vpc_key].route_tables :

            "${vpc_key}-${replace(replace(remote_cidr, ".", "-"), "/", "-")}-${route_table_key}" => {
              route_table_id         = route_table.id
              destination_cidr_block = remote_cidr

              target = {
                transit_gateway_id = module.transit_gateway.id
              }
            }

            if contains(
              external_config.route_table_groups,
              route_table.group
            )
          }
        ]...
      )
    ]...
  )
}

module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = merge(
    local.platform_vpc_routes,
    local.external_peer_vpc_routes
  )

  transit_gateway_routes = {}

  route_table_associations                 = {}
  transit_gateway_route_table_associations = {}
  transit_gateway_route_table_propagations = {}
}
