##################################################################################################
# Centralized Inspection VPC
##################################################################################################
# The approved Inspection VPC and subnet CIDRs are supplied by var.network_config.
#
# It contains two dedicated Network Firewall endpoint subnets and two Transit Gateway attachment
# subnets. routing.tf provides the same-Availability-Zone path from each TGW attachment subnet to its
# firewall endpoint and the return path from each firewall subnet to Transit Gateway.
#
# The VPC has no Internet Gateway, NAT Gateway, public subnet, or internet default route.

locals {
  inspection_vpc = {
    vpc_name   = local.resource_names.inspection_vpc
    cidr_block = local.network_cidrs.inspection

    # Unallocated address space remains reserved for future inspection services and growth.
    route_tables = {
      firewall-a = {
        group = "network-firewall"
      }

      firewall-b = {
        group = "network-firewall"
      }

      transit-gateway-a = {
        group = "transit-gateway"
      }

      transit-gateway-b = {
        group = "transit-gateway"
      }
    }

    subnets = {
      firewall-a = {
        cidr_block              = var.network_config.vpcs.inspection.subnet_cidrs.firewall_a
        availability_zone_index = 0
        group                   = "network-firewall"
        route_table_key         = "firewall-a"
      }

      firewall-b = {
        cidr_block              = var.network_config.vpcs.inspection.subnet_cidrs.firewall_b
        availability_zone_index = 1
        group                   = "network-firewall"
        route_table_key         = "firewall-b"
      }

      transit-gateway-a = {
        cidr_block              = var.network_config.vpcs.inspection.subnet_cidrs.transit_gateway_a
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }

      transit-gateway-b = {
        cidr_block              = var.network_config.vpcs.inspection.subnet_cidrs.transit_gateway_b
        availability_zone_index = 1
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-b"
      }
    }
  }
}

# Purpose: Creates the centralized Inspection VPC that hosts AWS Network Firewall endpoints.
# Change when: Change firewall and TGW subnet allocations together to preserve Availability Zone alignment.
# The Inspection VPC remains provisioned in bypass mode.
# Bypass mode removes the Network Firewall and its TGW attachment while
# retaining the network structure so inspection can be re-enabled cleanly.
module "inspection_vpc" {
  source = "../../modules/vpc"

  vpc_name   = local.inspection_vpc.vpc_name
  cidr_block = local.inspection_vpc.cidr_block

  route_tables = local.inspection_vpc.route_tables
  subnets      = local.inspection_vpc.subnets

  create_internet_gateway = false

  tags = local.org_tags
}
