##################################################################################################
# Networking
##################################################################################################

############################################
# Recovery Access VPC
############################################
# Entry point for administrators before they reach recovery workloads.
# This is the only VPC in the topology that would host public subnets
# in a production layout (disabled here for the sandbox). All traffic
# into the IRE is expected to land here first, then hop to Core Recovery
# over the Transit Gateway per the trust model below.

# Static network parameters (CIDR, subnet layout and VPC name) are defined
# in locals.tf; this module consumes those values and builds the network.

module "recovery_access" {

  source = "../../modules/vpc"

  vpc_name                = local.recovery_access.vpc_name
  cidr_block              = local.recovery_access.cidr_block
  availability_zone_count = local.recovery_access.availability_zone_count

  # public_subnets = {   blocking entire section for now, since we don't want public subnets in the sandbox
  #  public-a = "10.100.1.0/24"
  #  public-b = "10.100.2.0/24"
  #}

  private_subnets = local.recovery_access.private_subnets

  # Install routes in the private route table for networks reachable via
  # the Transit Gateway. Under the IRE trust model, the Recovery Access VPC
  # communicates only with the Core Recovery VPC.

  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}

############################################
# Core Recovery VPC
############################################
# Hosts the recovery tooling and compute tier, and acts as the central
# routing domain within the IRE. No public_subnets input is given, so
# the module falls back to its default of {} and creates no public
# subnets, no Internet Gateway, and no public route table for this VPC.
module "core_recovery" {

  source = "../../modules/vpc"

  vpc_name                = local.core_recovery.vpc_name
  cidr_block              = local.core_recovery.cidr_block
  availability_zone_count = local.core_recovery.availability_zone_count

  private_subnets = local.core_recovery.private_subnets

  # Core Recovery acts as the central routing domain within the IRE. It
  # requires routes to both the Recovery Access and Protected Data VPCs.
  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.recovery_access.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    },
    {
      destination_cidr_block = module.protected_data.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}

############################################
# Protected Data VPC
############################################
# Holds the immutable backup data - the most sensitive tier in the IRE.
# Private subnets only, same isolation pattern as Core Recovery. Direct
# routing to Recovery Access is intentionally omitted below so that
# administrators can never reach protected data without transiting
# Core Recovery first.
module "protected_data" {

  source = "../../modules/vpc"

  vpc_name                = local.protected_data.vpc_name
  cidr_block              = local.protected_data.cidr_block
  availability_zone_count = local.protected_data.availability_zone_count

  private_subnets = local.protected_data.private_subnets

  # Install routes for the Core Recovery VPC only. Direct routing to the
  # Recovery Access VPC is intentionally omitted to enforce the IRE trust
  # model.
  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}

############################################
# Transit Gateway
############################################
# The Transit Gateway is the central router connecting all three VPCs.
#
# Trust Model
#
#   Recovery Access <------> Core Recovery <------> Protected Data
#
# Recovery Access has no direct path to Protected Data. All traffic must
# traverse Core Recovery.
#
# Transit Gateway Route Tables define the routing domains, while the VPC
# attachments below define:
#
#   1. Which Transit Gateway Route Table each VPC attachment is associated with.
#   2. Which Transit Gateway Route Tables learn routes from each VPC.

module "transit_gateway" {

  source = "../../modules/transit-gateway"

  name = local.transit_gateway.name

  default_route_table_association = local.transit_gateway.default_route_table_association
  default_route_table_propagation = local.transit_gateway.default_route_table_propagation

  # Transit Gateway Route Tables.
  # The map keys are logical identifiers used by the VPC attachments below.
  route_tables = local.transit_gateway.route_tables

  ##########################################################################
  # VPC Attachments
  ##########################################################################
  #
  # Each attachment performs two independent actions:
  #
  # route_table
  #   Associates the VPC attachment with one Transit Gateway Route Table.
  #
  # propagate_to
  #   Advertises this VPC's CIDR block into one or more Transit Gateway
  #   Route Tables so those routing domains learn how to reach this VPC.
  #
  # IMPORTANT:
  # The values "recovery_access", "core_recovery" and "protected_data"
  # reference the Transit Gateway Route Table KEYS defined above.
  # They do NOT refer to VPC Route Tables.
  ##########################################################################

  vpc_attachments = {

    ######################################################################
    # Recovery Access VPC
    ######################################################################
    recovery_access = {

      vpc_id     = module.recovery_access.vpc_id
      subnet_ids = module.recovery_access.private_subnet_ids

      # Associate this VPC attachment with the
      # Recovery Access Transit Gateway Route Table.
      route_table = "recovery_access"

      # Advertise the Recovery Access VPC CIDR into the
      # Core Recovery Transit Gateway Route Table.
      propagate_to = [
        "core_recovery"
      ]
    }

    ######################################################################
    # Core Recovery VPC
    ######################################################################
    core_recovery = {

      vpc_id     = module.core_recovery.vpc_id
      subnet_ids = module.core_recovery.private_subnet_ids

      # Associate this VPC attachment with the
      # Core Recovery Transit Gateway Route Table.
      route_table = "core_recovery"

      # Advertise the Core Recovery VPC CIDR into both the
      # Recovery Access and Protected Data Transit Gateway
      # Route Tables.
      propagate_to = [
        "recovery_access",
        "protected_data"
      ]
    }

    ######################################################################
    # Protected Data VPC
    ######################################################################
    protected_data = {

      vpc_id     = module.protected_data.vpc_id
      subnet_ids = module.protected_data.private_subnet_ids

      # Associate this VPC attachment with the
      # Protected Data Transit Gateway Route Table.
      route_table = "protected_data"

      # Advertise the Protected Data VPC CIDR into the
      # Core Recovery Transit Gateway Route Table.
      propagate_to = [
        "core_recovery"
      ]
    }
  }

  tags = merge(
    local.org_tags,
    {
      Name = local.transit_gateway.name
    }
  )

}