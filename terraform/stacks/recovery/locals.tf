locals {
  ##################################################################################################
  # Naming
  ##################################################################################################

  region_code_by_region = {
    "us-east-1"  = "use1"
    "us-east-2"  = "use2"
    "us-west-1"  = "usw1"
    "us-west-2"  = "usw2"
    "ap-south-1" = "aps1"
    "ap-south-2" = "aps2"
    "eu-west-1"  = "euw1"
    "eu-west-2"  = "euw2"
  }

  effective_region_code = coalesce(
    var.naming.region_code,
    lookup(
      local.region_code_by_region,
      var.aws_region,
      replace(lower(trimspace(var.aws_region)), "-", "")
    )
  )

  name_prefix = join("-", compact([
    lower(trimspace(var.naming.organization)),
    lower(trimspace(var.naming.project)),
    lower(trimspace(var.naming.environment)),
    local.effective_region_code,
    var.naming.suffix == null ? "" : lower(trimspace(var.naming.suffix)),
  ]))

  resource_names = {
    backup_plan = coalesce(
      var.resource_name_overrides.backup_plan,
      "${local.name_prefix}-backup-plan"
    )

    backup_role = coalesce(
      var.resource_name_overrides.backup_role,
      "${local.name_prefix}-backup-role"
    )

    backup_selection = coalesce(
      var.resource_name_overrides.backup_selection,
      "${local.name_prefix}-backup-selection"
    )
  }

  ##################################################################################################
  # Organization Tags
  ##################################################################################################

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
}
