locals {
  name_prefix = "ire-client-vpn-ad-poc"

  required_tag_values = {
    it_cost_center       = var.org_it_cost_center
    department           = var.org_department
    cmdb_calculated_app  = var.org_cmdb_calculated_app
    business_criticality = var.org_business_criticality
    environment          = var.org_environment
    data_classification  = var.org_data_classification
    project_name         = var.org_project_name
    managed_by           = var.org_managed_by
  }

  required_tags = {
    for key, value in local.required_tag_values :
    "${var.organization_tag_key_prefix}${key}" => value
  }

  tags = merge(var.org_additional_tags, local.required_tags)

  route_tables = {
    directory-a = { group = "directory-services" }
    directory-b = { group = "directory-services" }
  }

  subnets = {
    directory-a = {
      cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 10)
      availability_zone_index = 0
      group                   = "directory-services"
      route_table_key         = "directory-a"
    }
    directory-b = {
      cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 20)
      availability_zone_index = 1
      group                   = "directory-services"
      route_table_key         = "directory-b"
    }
  }
}
