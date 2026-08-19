output "standard_backup_vault_name" {
  description = "Persistent standard AWS Backup vault name, or null when vault management is disabled."
  value       = try(module.backup_standard_vault[0].name, null)
}

output "standard_backup_vault_arn" {
  description = "Persistent standard AWS Backup vault ARN, or null when vault management is disabled."
  value       = try(module.backup_standard_vault[0].arn, null)
}

output "air_gapped_backup_vault_name" {
  description = "Persistent logically air-gapped AWS Backup vault name, or null when vault management is disabled."
  value       = try(module.backup_logically_air_gapped_vault[0].name, null)
}

output "air_gapped_backup_vault_arn" {
  description = "Persistent logically air-gapped AWS Backup vault ARN, or null when vault management is disabled."
  value       = try(module.backup_logically_air_gapped_vault[0].arn, null)
}

output "network_firewall_logging_kms_key_arn" {
  description = "Persistent logging KMS key ARN, or null when customer-managed log encryption is disabled."
  value       = try(module.network_firewall_logging_kms[0].key_arn, null)
}
