locals {
  standard_backup_vault_name   = "${var.name_prefix}-standard-backup-vault"
  air_gapped_backup_vault_name = "${var.name_prefix}-airgap-backup-vault"

  network_firewall_logging_kms_alias = "${var.name_prefix}-network-firewall-logs"

  network_firewall_logging_kms_description = (
    "Persistent customer-managed KMS key for IRE Network Firewall CloudWatch logs"
  )

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
}
