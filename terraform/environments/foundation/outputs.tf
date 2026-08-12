output "standard_backup_vault_name" {
  description = "Persistent standard AWS Backup vault name."
  value       = module.backup_standard_vault.name
}

output "standard_backup_vault_arn" {
  description = "Persistent standard AWS Backup vault ARN."
  value       = module.backup_standard_vault.arn
}

output "air_gapped_backup_vault_name" {
  description = "Persistent logically air-gapped AWS Backup vault name."
  value       = module.backup_logically_air_gapped_vault.name
}

output "air_gapped_backup_vault_arn" {
  description = "Persistent logically air-gapped AWS Backup vault ARN."
  value       = module.backup_logically_air_gapped_vault.arn
}

output "network_firewall_logging_kms_key_arn" {
  description = "Persistent KMS key ARN used by Network Firewall CloudWatch log groups."
  value       = module.network_firewall_logging_kms.key_arn
}
