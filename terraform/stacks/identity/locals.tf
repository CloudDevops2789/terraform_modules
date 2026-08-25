locals {
  org_required_tags = {
    "${var.organization_tag_key_prefix}it_cost_center"       = var.org_it_cost_center
    "${var.organization_tag_key_prefix}department"           = var.org_department
    "${var.organization_tag_key_prefix}cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "${var.organization_tag_key_prefix}business_criticality" = var.org_business_criticality
    "${var.organization_tag_key_prefix}environment"          = var.org_environment
    "${var.organization_tag_key_prefix}data_classification"  = var.org_data_classification
    "${var.organization_tag_key_prefix}project_name"         = var.org_project_name
    "${var.organization_tag_key_prefix}managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )
}
