##################################################################################################
# Generic VPC / Transit Gateway / Inspection Routing
##################################################################################################

locals {
  ################################################################################################
  # VPC route-table routes generated from connectivity policy
  ################################################################################################

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
  # Centralized inspection same-AZ routing
  ################################################################################################

  inspection_routing_zones = (
    local.network_firewall_enabled
    ? {
      for subnet_key, transit_gateway_subnet in module.vpc[
        local.inspection_vpc_key
      ].subnets :

      transit_gateway_subnet.availability_zone => {
        transit_gateway_route_table_id = (
          transit_gateway_subnet.route_table_id
        )

        firewall_route_table_id = one([
          for firewall_subnet in values(
            module.vpc[
              local.inspection_vpc_key
            ].subnets
          ) :
          firewall_subnet.route_table_id
          if(
            firewall_subnet.group ==
            local.inspection_firewall_subnet_group &&
            firewall_subnet.availability_zone ==
            transit_gateway_subnet.availability_zone
          )
        ])
      }

      if(
        transit_gateway_subnet.group ==
        local.inspection_transit_gateway_subnet_group
      )
    }
    : {}
  )

  inspection_spoke_cidrs = (
    local.network_firewall_enabled
    ? {
      for vpc_key, vpc in local.transit_gateway_vpcs :
      vpc_key => module.vpc[vpc_key].vpc_cidr
      if vpc_key != local.inspection_vpc_key
    }
    : {}
  )

  inspection_tgw_to_firewall_routes = (
    local.network_firewall_enabled
    ? merge(
      {},
      [
        for availability_zone, zone in local.inspection_routing_zones : {
          for spoke_key, spoke_cidr in local.inspection_spoke_cidrs :

          "inspection-tgw-${availability_zone}-${spoke_key}" => {
            route_table_id         = zone.transit_gateway_route_table_id
            destination_cidr_block = spoke_cidr

            target = {
              vpc_endpoint_id = (
                module.network_firewall
                .endpoint_ids_by_availability_zone["inspection"][
                  availability_zone
                ]
              )
            }
          }
        }
      ]...
    )
    : {}
  )

  inspection_firewall_to_tgw_routes = (
    local.network_firewall_enabled
    ? merge(
      {},
      [
        for availability_zone, zone in local.inspection_routing_zones : {
          for spoke_key, spoke_cidr in local.inspection_spoke_cidrs :

          "inspection-firewall-${availability_zone}-${spoke_key}" => {
            route_table_id         = zone.firewall_route_table_id
            destination_cidr_block = spoke_cidr

            target = {
              transit_gateway_id = module.transit_gateway.id
            }
          }
        }
      ]...
    )
    : {}
  )

  ################################################################################################
  # TGW source-domain routes through inspection attachment
  ################################################################################################

  inspection_transit_gateway_routes = (
    local.network_firewall_enabled
    ? {
      for edge_key, edge in var.network_config.connectivity :

      edge_key => {
        transit_gateway_route_table_id = (
          module.transit_gateway.route_table_ids[
            edge.source_vpc_key
          ]
        )

        destination_cidr_block = module.vpc[
          edge.destination_vpc_key
        ].vpc_cidr

        transit_gateway_attachment_id = (
          module.transit_gateway.attachment_ids[
            local.inspection_vpc_key
          ]
        )
      }
    }
    : {}
  )
}

module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = merge(
    local.platform_vpc_routes,
    local.inspection_tgw_to_firewall_routes,
    local.inspection_firewall_to_tgw_routes
  )

  transit_gateway_routes = (
    local.inspection_transit_gateway_routes
  )

  route_table_associations                 = {}
  transit_gateway_route_table_associations = {}
  transit_gateway_route_table_propagations = {}
}
