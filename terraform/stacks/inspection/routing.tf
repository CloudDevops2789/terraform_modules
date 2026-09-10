##################################################################################################
# Firewall-Dependent Inspection Routing
##################################################################################################
#
# Platform owns base topology and ordinary VPC -> Transit Gateway routes.
#
# Inspection owns only routes whose correctness depends on the AWS Network
# Firewall lifecycle:
#
#   Inspection TGW subnet route table -> same-AZ firewall endpoint
#   Inspection firewall subnet route table -> Transit Gateway
#   source-domain TGW route table -> Inspection VPC attachment
#
# This maintains symmetric centralized inspection without transferring ordinary
# Platform routing into the Inspection state.
##################################################################################################

locals {
  ################################################################################################
  # Same-AZ Inspection Routing Metadata
  ################################################################################################

  inspection_routing_zones = {
    for availability_zone, transit_gateway_subnet
    in var.inspection_contract.inspection_vpc.transit_gateway_subnets_by_az :

    availability_zone => {
      transit_gateway_route_table_id = (
        transit_gateway_subnet.route_table_id
      )

      firewall_route_table_id = (
        var.inspection_contract
        .inspection_vpc
        .firewall_subnets_by_az[availability_zone]
        .route_table_id
      )
    }
  }

  inspection_spoke_cidrs = {
    for vpc_key, vpc in var.inspection_contract.spoke_vpcs :
    vpc_key => vpc.cidr_block
  }

  ################################################################################################
  # Inspection TGW subnet -> same-AZ Network Firewall endpoint
  ################################################################################################

  inspection_tgw_to_firewall_routes = merge(
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

  ################################################################################################
  # Network Firewall subnet -> Transit Gateway
  ################################################################################################

  inspection_firewall_to_tgw_routes = merge(
    {},
    [
      for availability_zone, zone in local.inspection_routing_zones : {
        for spoke_key, spoke_cidr in local.inspection_spoke_cidrs :

        "inspection-firewall-${availability_zone}-${spoke_key}" => {
          route_table_id         = zone.firewall_route_table_id
          destination_cidr_block = spoke_cidr

          target = {
            transit_gateway_id = (
              var.inspection_contract.transit_gateway_id
            )
          }
        }
      }
    ]...
  )

  ################################################################################################
  # Source-domain TGW route table -> Inspection attachment
  ################################################################################################

  inspection_transit_gateway_routes = {
    for edge_key, edge in var.inspection_contract.connectivity :

    edge_key => {
      transit_gateway_route_table_id = (
        var.inspection_contract
        .spoke_vpcs[edge.source_vpc_key]
        .transit_gateway_route_table_id
      )

      destination_cidr_block = (
        var.inspection_contract
        .spoke_vpcs[edge.destination_vpc_key]
        .cidr_block
      )

      transit_gateway_attachment_id = (
        var.inspection_contract
        .inspection_vpc
        .transit_gateway_attachment_id
      )
    }
  }
}

module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = merge(
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
