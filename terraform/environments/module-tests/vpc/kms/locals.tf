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
  # KMS Under Test
  ##################################################################################################
  # The kms module is fully self-contained: it resolves the calling AWS
  # identity itself (bootstrap_current_caller defaults to true) rather than
  # requiring the caller to supply administrator ARNs, so no supporting
  # resources are needed to validate that it deploys.
  kms = {
    description = "Module test - customer managed KMS key"
    alias       = "module-test-kms"
  }
}
