##################################################################################################
# Centralized Inspection VPC
##################################################################################################
# This VPC uses the fourth /24 inside the account-approved 10.213.252.0/22 allocation.
#
# It contains two dedicated Network Firewall endpoint subnets and two Transit Gateway attachment
# subnets. routing.tf provides the same-Availability-Zone path from each TGW attachment subnet to its
# firewall endpoint and the return path from each firewall subnet to Transit Gateway.
#
# The VPC has no Internet Gateway, NAT Gateway, public subnet, or internet default route.

locals {
  inspection_vpc = {
    vpc_name   = "centralized-inspection"
    cidr_block = "10.213.255.0/24"

    # 10.213.255.64/26 and 10.213.255.128/25 remain reserved for future
    # inspection services, controlled egress, endpoints, or growth.
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
        cidr_block              = "10.213.255.0/28"
        availability_zone_index = 0
        group                   = "network-firewall"
        route_table_key         = "firewall-a"
      }

      firewall-b = {
        cidr_block              = "10.213.255.16/28"
        availability_zone_index = 1
        group                   = "network-firewall"
        route_table_key         = "firewall-b"
      }

      transit-gateway-a = {
        cidr_block              = "10.213.255.32/28"
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }

      transit-gateway-b = {
        cidr_block              = "10.213.255.48/28"
        availability_zone_index = 1
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-b"
      }
    }
  }
}

module "inspection_vpc" {
  source = "../../modules/vpc"

  vpc_name   = local.inspection_vpc.vpc_name
  cidr_block = local.inspection_vpc.cidr_block

  route_tables = local.inspection_vpc.route_tables
  subnets      = local.inspection_vpc.subnets

  create_internet_gateway = false

  tags = local.org_tags
}
