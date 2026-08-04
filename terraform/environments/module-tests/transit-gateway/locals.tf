locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  default_tags = merge(
    {
      org_it_cost_center       = var.org_it_cost_center
      org_department           = var.org_department
      org_cmdb_calculated_app  = var.org_cmdb_calculated_app
      org_business_criticality = var.org_business_criticality
      org_environment          = var.org_environment
      org_data_classification  = var.org_data_classification

      Project   = var.project_name
      ManagedBy = "Terraform"
    },
    var.additional_tags
  )

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # The transit-gateway module has no reachability of its own - a Transit
  # Gateway attachment must point at a real VPC and real subnet IDs. This
  # single VPC exists ONLY to give the module under test something to
  # attach to; the VPC itself is not under test (see the vpc/ module test
  # for that).
  vpc = {
    vpc_name                = "module-test-tgw-vpc"
    cidr_block              = "10.251.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.251.11.0/24"
    }
  }

  ##################################################################################################
  # Transit Gateway Under Test
  ##################################################################################################
  # The minimum shape that exercises the module's core resources: the
  # gateway itself, one Transit Gateway Route Table, one VPC attachment,
  # the association binding the attachment to that route table, and one
  # propagation. A single route table stands in for the multi-route-table
  # segmented routing sandbox uses in production - segmentation itself is
  # not what this test is validating.
  transit_gateway = {
    name = "module-test-transit-gateway"

    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    route_tables = {
      main = {
        name = "Module Test Route Table"
      }
    }
  }
}
