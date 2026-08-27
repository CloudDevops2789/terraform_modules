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
  # AWS Managed Microsoft AD requires exactly two subnet IDs in two
  # different Availability Zones (enforced by the module's own variable
  # validation). A minimal VPC with two private subnets exists only to
  # satisfy that requirement; the VPC itself is not under test.
  vpc = {
    vpc_name   = "module-test-ad-vpc"
    cidr_block = "10.249.0.0/16"

    route_tables = {
      directory-services-a = {
        group = "directory-services"
      }

      directory-services-b = {
        group = "directory-services"
      }
    }

    subnets = {
      directory-services-a = {
        cidr_block              = "10.249.11.0/24"
        availability_zone_index = 0
        group                   = "directory-services"
        route_table_key         = "directory-services-a"
      }

      directory-services-b = {
        cidr_block              = "10.249.12.0/24"
        availability_zone_index = 1
        group                   = "directory-services"
        route_table_key         = "directory-services-b"
      }
    }
  }

  ##################################################################################################
  # Managed Microsoft AD Under Test
  ##################################################################################################
  # The directory's domain name is static deployment configuration and
  # belongs here. Its password is a secret and is intentionally kept out
  # of locals.tf - see variables.tf and terraform.tfvars.example.
  managed_ad = {
    domain_name = "moduletest.example.com"
    edition     = "Standard" # cheapest edition; sufficient to prove the module deploys
  }
}
