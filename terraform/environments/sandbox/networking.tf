##################################################################################################
# VPCs
##################################################################################################
# The environment owns CIDRs, subnet roles, AZ placement, and route-table
# relationships. The reusable VPC module creates no routes.

module "recovery_access" {
  source = "../../modules/vpc"

  vpc_name   = local.recovery_access.vpc_name
  cidr_block = local.recovery_access.cidr_block

  route_tables = local.recovery_access.route_tables
  subnets      = local.recovery_access.subnets

  create_internet_gateway = false

  tags = local.org_tags
}

module "core_recovery" {
  source = "../../modules/vpc"

  vpc_name   = local.core_recovery.vpc_name
  cidr_block = local.core_recovery.cidr_block

  route_tables = local.core_recovery.route_tables
  subnets      = local.core_recovery.subnets

  create_internet_gateway = false

  tags = local.org_tags
}

module "protected_data" {
  source = "../../modules/vpc"

  vpc_name   = local.protected_data.vpc_name
  cidr_block = local.protected_data.cidr_block

  route_tables = local.protected_data.route_tables
  subnets      = local.protected_data.subnets

  create_internet_gateway = false

  tags = local.org_tags
}

##################################################################################################
# Transit Gateway
##################################################################################################
# Every approved inter-VPC path is steered first to the centralized Inspection VPC attachment.
# Recovery Access and Protected Data still receive no route to one another.

module "transit_gateway" {
  source = "../../modules/transit-gateway"

  name = local.transit_gateway.name

  default_route_table_association = local.transit_gateway.default_route_table_association
  default_route_table_propagation = local.transit_gateway.default_route_table_propagation

  route_tables = merge(
    local.transit_gateway.route_tables,
    {
      inspection = {
        name = "Centralized Inspection Route Table"
      }
    }
  )

  vpc_attachments = {
    recovery_access = {
      vpc_id       = module.recovery_access.vpc_id
      subnet_ids   = module.recovery_access.subnet_ids_by_group["transit-gateway"]
      route_table  = "recovery_access"
      propagate_to = ["inspection"]
    }

    core_recovery = {
      vpc_id       = module.core_recovery.vpc_id
      subnet_ids   = module.core_recovery.subnet_ids_by_group["transit-gateway"]
      route_table  = "core_recovery"
      propagate_to = ["inspection"]
    }

    protected_data = {
      vpc_id       = module.protected_data.vpc_id
      subnet_ids   = module.protected_data.subnet_ids_by_group["transit-gateway"]
      route_table  = "protected_data"
      propagate_to = ["inspection"]
    }

    inspection = {
      vpc_id       = module.inspection_vpc.vpc_id
      subnet_ids   = module.inspection_vpc.subnet_ids_by_group["transit-gateway"]
      route_table  = "inspection"
      propagate_to = []

      # Appliance mode preserves Availability Zone affinity and symmetric
      # forwarding for stateful inspection when traffic steering is enabled.
      appliance_mode_support = "enable"
    }
  }

  tags = merge(
    local.org_tags,
    {
      Name = local.transit_gateway.name
    }
  )
}
