##################################################################################################
# Generic VPC Composition
##################################################################################################

module "vpc" {
  for_each = local.vpc_definitions

  source = "../../modules/vpc"

  vpc_name   = each.value.vpc_name
  cidr_block = each.value.cidr_block

  route_tables = each.value.route_tables
  subnets      = each.value.subnets

  create_internet_gateway = each.value.create_internet_gateway

  tags = local.org_tags
}

##################################################################################################
# Generic Transit Gateway Composition
##################################################################################################

locals {
  transit_gateway_vpcs = {
    for vpc_key, vpc in local.vpc_definitions :
    vpc_key => vpc
    if(
      vpc.transit_gateway.enabled &&
      (
        vpc_key != local.inspection_vpc_key ||
        local.network_firewall_enabled
      )
    )
  }

  bypass_propagation_targets = {
    for destination_vpc_key in keys(local.transit_gateway_vpcs) :
    destination_vpc_key => distinct([
      for edge in values(var.network_config.connectivity) :
      edge.source_vpc_key
      if(
        edge.destination_vpc_key == destination_vpc_key &&
        contains(
          keys(local.transit_gateway_vpcs),
          edge.source_vpc_key
        )
      )
    ])
  }

  transit_gateway_route_tables = {
    for vpc_key, vpc in local.transit_gateway_vpcs :
    vpc_key => {
      name = coalesce(
        vpc.transit_gateway.route_table_name,
        "${local.name_prefix}-${replace(vpc_key, "_", "-")}-tgw-rt"
      )
    }
  }

  transit_gateway_attachments = {
    for vpc_key, vpc in local.transit_gateway_vpcs :
    vpc_key => {
      vpc_id = module.vpc[vpc_key].vpc_id

      subnet_ids = module.vpc[
        vpc_key
      ].subnet_ids_by_group["transit-gateway"]

      route_table = vpc_key

      propagate_to = (
        local.network_firewall_enabled
        ? (
          vpc_key == local.inspection_vpc_key
          ? []
          : [local.inspection_vpc_key]
        )
        : local.bypass_propagation_targets[vpc_key]
      )

      appliance_mode_support = (
        vpc.transit_gateway.appliance_mode_support
      )
    }
  }
}

module "transit_gateway" {
  source = "../../modules/transit-gateway"

  name = local.resource_names.transit_gateway

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  route_tables    = local.transit_gateway_route_tables
  vpc_attachments = local.transit_gateway_attachments

  tags = merge(
    local.org_tags,
    {
      Name = local.resource_names.transit_gateway
    }
  )
}
