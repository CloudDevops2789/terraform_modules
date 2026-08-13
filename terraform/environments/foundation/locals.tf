locals {
  standard_backup_vault_name   = "${var.name_prefix}-standard-backup-vault"
  air_gapped_backup_vault_name = "${var.name_prefix}-airgap-backup-vault"

  network_firewall_logging_kms_alias = "${var.name_prefix}-network-firewall-logs"

  network_firewall_logging_kms_description = (
    "Persistent customer-managed KMS key for IRE Network Firewall CloudWatch logs"
  )
}
