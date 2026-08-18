locals {
  standard_backup_vault_name   = "${var.name_prefix}-standard-backup-vault"
  air_gapped_backup_vault_name = "${var.name_prefix}-airgap-backup-vault"

  network_firewall_logging_kms_alias = "${var.name_prefix}-network-firewall-logs"

  network_firewall_logging_kms_description = (
    "Persistent customer-managed KMS key for IRE Network Firewall CloudWatch logs"
  )

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
}
