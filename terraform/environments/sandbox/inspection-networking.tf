##################################################################################################
# Centralized Inspection VPC Foundation
##################################################################################################
# This VPC reserves the fourth /24 inside the account-approved 10.213.252.0/22 allocation.
#
# This stage creates only:
# - the Inspection VPC;
# - two dedicated Network Firewall subnets;
# - two Transit Gateway attachment subnets;
# - explicit route tables and subnet associations;
# - an appliance-mode Transit Gateway attachment.
#
# It does not yet create AWS Network Firewall, firewall policies, logging destinations, Internet
# Gateways, NAT Gateways, default routes, or traffic-steering routes. Existing Sandbox traffic paths
# therefore remain unchanged until the dedicated firewall-routing stage is introduced.

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
