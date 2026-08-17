locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    "fv:it_cost_center"       = var.org_it_cost_center
    "fv:department"           = var.org_department
    "fv:cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "fv:business_criticality" = var.org_business_criticality
    "fv:environment"          = var.org_environment
    "fv:data_classification"  = var.org_data_classification
    "fv:project_name"         = var.org_project_name
    "fv:managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # A security group must belong to a VPC. A minimal VPC exists here only
  # to give the group a real vpc_id; the VPC itself is not under test.
  vpc = {
    vpc_name   = "module-test-sg-vpc"
    cidr_block = "10.253.0.0/16"

    route_tables = {
      private-a = {
        group = "supporting"
      }
    }

    subnets = {
      private-a = {
        cidr_block              = "10.253.11.0/24"
        availability_zone_index = 0
        group                   = "supporting"
        route_table_key         = "private-a"
      }
    }
  }

  ##################################################################################################
  # Security Groups and Rules Under Test
  ##################################################################################################
  # security-group and security-group-rule are two separate modules that
  # are always used together (a rule cannot exist without a group to attach
  # to), so this test validates both. One group with one ingress and one
  # egress rule is the minimum shape that exercises: group creation, the
  # ingress/egress split in security-group-rule's locals, and both standalone
  # rule resource types.
  security_groups = {
    tiers = {
      management = {
        description = "Module test - Security Group"
      }
    }

    rules = {
      ssh_ingress = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_ipv4   = "10.253.0.0/16"
      }

      all_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }
}
