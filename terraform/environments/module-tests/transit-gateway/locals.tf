locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    "org_it_cost_center"       = var.org_it_cost_center
    "org_department"           = var.org_department
    "org_cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "org_business_criticality" = var.org_business_criticality
    "org_environment"          = var.org_environment
    "org_data_classification"  = var.org_data_classification
    "org_project_name"         = var.org_project_name
    "org_managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
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
    vpc_name   = "module-test-tgw-vpc"
    cidr_block = "10.251.0.0/16"

    route_tables = {
      attachment-a = {
        group = "transit-gateway"
      }
    }

    subnets = {
      private-a = {
        cidr_block              = "10.251.11.0/24"
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "attachment-a"
      }
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
