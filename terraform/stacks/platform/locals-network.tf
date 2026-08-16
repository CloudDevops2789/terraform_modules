locals {
  ##################################################################################################
  # Generic VPC Definitions
  ##################################################################################################

  vpc_definitions = {
    for vpc_key, vpc in var.network_config.vpcs :
    vpc_key => {
      vpc_name = coalesce(
        vpc.name,
        "${local.name_prefix}-${replace(vpc_key, "_", "-")}-vpc"
      )

      cidr_block              = vpc.cidr_block
      route_tables            = vpc.route_tables
      subnets                 = vpc.subnets
      create_internet_gateway = vpc.create_internet_gateway
      transit_gateway         = vpc.transit_gateway
    }
  }

  network_firewall_enabled = (
    var.network_inspection_mode == "firewall"
  )

  inspection_vpc_key = try(
    var.network_config.inspection.vpc_key,
    null
  )

  inspection_firewall_subnet_group = try(
    var.network_config.inspection.firewall_subnet_group,
    "network-firewall"
  )

  inspection_transit_gateway_subnet_group = try(
    var.network_config.inspection.transit_gateway_subnet_group,
    "transit-gateway"
  )
}
