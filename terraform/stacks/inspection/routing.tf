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

  ################################################################################################
  # External Peer TGW Route Table -> Inspection attachment
  ################################################################################################
  #
  # Traffic entering through the external Transit Gateway peer for the IRE
  # address space must first enter the Inspection VPC. The dedicated external
  # peer route table therefore has no direct route to any recovery VPC.
  ################################################################################################

  external_peer_to_inspection_routes = (
    var.inspection_contract.external_peering == null
    ? {}
    : {
      for destination_cidr
      in var.inspection_contract.external_peering.external_to_ire_cidrs :

      "external-to-ire-${replace(replace(destination_cidr, ".", "-"), "/", "-")}" => {
        transit_gateway_route_table_id = (
          var.inspection_contract
          .external_peering
          .transit_gateway_route_table_id
        )

        destination_cidr_block = destination_cidr

        transit_gateway_attachment_id = (
          var.inspection_contract
          .inspection_vpc
          .transit_gateway_attachment_id
        )
      }
    }
  )

  ################################################################################################
  # Source-domain TGW Route Tables -> Inspection attachment for external networks
  ################################################################################################
  #
  # Selected IRE routing domains send approved remote enterprise CIDRs toward
  # the Inspection VPC. They never route directly to the peering attachment.
  ################################################################################################

  external_remote_to_inspection_routes = (
    var.inspection_contract.external_peering == null
    ? {}
    : merge(
      {},
      [
        for vpc_key in var.inspection_contract.external_peering.ire_to_external_vpc_keys : {
          for remote_cidr in var.inspection_contract.external_peering.remote_cidrs :

          "${vpc_key}-${replace(replace(remote_cidr, ".", "-"), "/", "-")}-to-inspection" => {
            transit_gateway_route_table_id = (
              var.inspection_contract
              .spoke_vpcs[vpc_key]
              .transit_gateway_route_table_id
            )

            destination_cidr_block = remote_cidr

            transit_gateway_attachment_id = (
              var.inspection_contract
              .inspection_vpc
              .transit_gateway_attachment_id
            )
          }
        }
      ]...
    )
  )

  ################################################################################################
  # Inspection TGW subnets -> Network Firewall for external networks
  ################################################################################################

  external_inspection_tgw_to_firewall_routes = (
    var.inspection_contract.external_peering == null
    ? {}
    : merge(
      {},
      [
        for availability_zone, zone in local.inspection_routing_zones : {
          for remote_cidr in var.inspection_contract.external_peering.remote_cidrs :

          "external-tgw-${availability_zone}-${replace(replace(remote_cidr, ".", "-"), "/", "-")}" => {
            route_table_id         = zone.transit_gateway_route_table_id
            destination_cidr_block = remote_cidr

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
  )

  ################################################################################################
  # Network Firewall subnets -> Transit Gateway for external networks
  ################################################################################################

  external_firewall_to_tgw_routes = (
    var.inspection_contract.external_peering == null
    ? {}
    : merge(
      {},
      [
        for availability_zone, zone in local.inspection_routing_zones : {
          for remote_cidr in var.inspection_contract.external_peering.remote_cidrs :

          "external-firewall-${availability_zone}-${replace(replace(remote_cidr, ".", "-"), "/", "-")}" => {
            route_table_id         = zone.firewall_route_table_id
            destination_cidr_block = remote_cidr

            target = {
              transit_gateway_id = (
                var.inspection_contract.transit_gateway_id
              )
            }
          }
        }
      ]...
    )
  )

  ################################################################################################
  # Inspection TGW Route Table -> External peering attachment
  ################################################################################################

  inspection_to_external_peer_routes = (
    var.inspection_contract.external_peering == null
    ? {}
    : {
      for remote_cidr in var.inspection_contract.external_peering.remote_cidrs :

      "inspection-to-external-${replace(replace(remote_cidr, ".", "-"), "/", "-")}" => {
        transit_gateway_route_table_id = (
          var.inspection_contract
          .inspection_vpc
          .transit_gateway_route_table_id
        )

        destination_cidr_block = remote_cidr

        transit_gateway_attachment_id = (
          var.inspection_contract
          .external_peering
          .transit_gateway_attachment_id
        )
      }
    }
  )
}

module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = merge(
    local.inspection_tgw_to_firewall_routes,
    local.inspection_firewall_to_tgw_routes,
    local.external_inspection_tgw_to_firewall_routes,
    local.external_firewall_to_tgw_routes
  )

  transit_gateway_routes = merge(
    local.inspection_transit_gateway_routes,
    local.external_peer_to_inspection_routes,
    local.external_remote_to_inspection_routes,
    local.inspection_to_external_peer_routes
  )

  route_table_associations                 = {}
  transit_gateway_route_table_associations = {}
  transit_gateway_route_table_propagations = {}
}
