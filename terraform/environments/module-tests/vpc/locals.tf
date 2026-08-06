locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied on top of the provider's default_tags so resources created by
  # this test are identifiable as throwaway module-validation infrastructure.
  org_required_tags = {
    org_it_cost_center       = var.org_it_cost_center
    org_department           = var.org_department
    org_cmdb_calculated_app  = var.org_cmdb_calculated_app
    org_business_criticality = var.org_business_criticality
    org_environment          = var.org_environment
    org_data_classification  = var.org_data_classification
    org_project_name         = var.org_project_name
    org_managed_by           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # VPC Under Test
  ##################################################################################################
  #
  # This test intentionally creates several subnet patterns:
  #
  # - application-a-1 and application-a-2 use the same Availability Zone;
  # - application-a-1 and application-a-2 share one route table;
  # - firewall-a uses the same Availability Zone but a different route table;
  # - application-b uses a second Availability Zone;
  # - subnet groups allow consumers to select related subnet IDs.
  #
  # This proves the module can scale to multiple subnet roles and multiple
  # subnets per Availability Zone without changing the module.

  vpc = {
    vpc_name   = "module-test-vpc"
    cidr_block = "10.250.0.0/16"

    route_tables = {
      application-a = {
        name  = "module-test-vpc-application-a"
        group = "application"
      }

      application-b = {
        name  = "module-test-vpc-application-b"
        group = "application"
      }

      firewall-a = {
        name  = "module-test-vpc-firewall-a"
        group = "firewall"
      }
    }

    subnets = {
      ################################################################################################
      # Availability Zone index 0
      ################################################################################################

      application-a-1 = {
        cidr_block              = "10.250.11.0/24"
        availability_zone_index = 0
        group                   = "application"
        route_table_key         = "application-a"
      }

      # A second application subnet in the same Availability Zone and using
      # the same route table. This is the scaling behaviour under test.
      application-a-2 = {
        cidr_block              = "10.250.12.0/24"
        availability_zone_index = 0
        group                   = "application"
        route_table_key         = "application-a"
      }

      # A firewall subnet in the same Availability Zone but associated with a
      # different route table.
      firewall-a = {
        cidr_block              = "10.250.21.0/28"
        availability_zone_index = 0
        group                   = "firewall"
        route_table_key         = "firewall-a"
      }

      ################################################################################################
      # Availability Zone index 1
      ################################################################################################

      application-b = {
        cidr_block              = "10.250.31.0/24"
        availability_zone_index = 1
        group                   = "application"
        route_table_key         = "application-b"
      }
    }
  }
}
