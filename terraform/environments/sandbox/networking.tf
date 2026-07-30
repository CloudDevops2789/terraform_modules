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
module "recovery_access" {

  source = "../../modules/vpc"

  vpc_name                = "recovery-access"
  cidr_block              = "10.100.0.0/16"
  availability_zone_count = 2

  # public_subnets = {   blocking entire section for now, since we don't want public subnets in the sandbox
  #  public-a = "10.100.1.0/24"
  #  public-b = "10.100.2.0/24"
  #}

  private_subnets = {
    private-a = "10.100.11.0/24"
    private-b = "10.100.12.0/24"
  }
  # Install routes in the private route table for networks reachable via
  # the Transit Gateway. Under the IRE trust model, the Recovery Access VPC
  # communicates only with the Core Recovery VPC.
  #public_transit_gateway_routes = [
  # {
  #   destination_cidr_block = module.core_recovery.vpc_cidr
  #   transit_gateway_id     = module.transit_gateway.id
  # }
  #]

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

  vpc_name                = "core-recovery"
  cidr_block              = "10.101.0.0/16"
  availability_zone_count = 2

  private_subnets = {
    private-a = "10.101.11.0/24"
    private-b = "10.101.12.0/24"
  }

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

  vpc_name                = "protected-data"
  cidr_block              = "10.102.0.0/16"
  availability_zone_count = 2

  private_subnets = {
    private-a = "10.102.11.0/24"
    private-b = "10.102.12.0/24"
  }

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
# The Transit Gateway is the central router connecting all three VPCs
# and is the mechanism that enforces the IRE trust chain: Recovery
# Access <-> Core Recovery <-> Protected Data, with no direct path
# between Recovery Access and Protected Data. Route table association
# and propagation are handled per-attachment below rather than through
# the TGW default route table, which is why default association and
# propagation are disabled.
module "transit_gateway" {

  source = "../../modules/transit-gateway"

  name = "ire-transit-gateway"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  # Transit Gateway route tables representing the routing domains within
  # the recovery environment. Attachments associate with these route tables
  # and propagate routes according to the configured trust model.
  route_tables = {

    recovery_access = {
      name = "Recovery Access"
    }

    core_recovery = {
      name = "Core Recovery"
    }

    protected_data = {
      name = "Protected Data"
    }

  }

  # A map(object) input: one entry per VPC to attach. Inside the module this map
  # is iterated with for_each, so each key (recovery_access, core_recovery, ...)
  # becomes a stable resource address like
  # aws_ec2_transit_gateway_vpc_attachment.this["recovery_access"].
  # Attachments are placed in the PRIVATE subnets - the TGW creates a network
  # interface in each subnet you list.
  vpc_attachments = {

    recovery_access = {
      vpc_id     = module.recovery_access.vpc_id
      subnet_ids = module.recovery_access.private_subnet_ids

      route_table = "recovery_access"

      propagate_to = [
        "core_recovery"
      ]
    }

    core_recovery = {
      vpc_id     = module.core_recovery.vpc_id
      subnet_ids = module.core_recovery.private_subnet_ids

      route_table = "core_recovery"

      propagate_to = [
        "recovery_access",
        "protected_data"
      ]
    }

    protected_data = {
      vpc_id     = module.protected_data.vpc_id
      subnet_ids = module.protected_data.private_subnet_ids

      route_table = "protected_data"

      propagate_to = [
        "core_recovery"
      ]
    }
  }

  # Merged onto the TGW resources by the module (see its locals.tf). These are
  # in addition to the provider-level default_tags defined in provider.tf.
  tags = {
    Name        = "ire-transit-gateway"
    Project     = "AWS-IRE"
    Environment = "Sandbox"
    ManagedBy   = "Terraform"
    Owner       = "CloudEngineering"
  }

}
