output "standard_vault_arn" {
  description = "ARN of the standard Backup Vault created by the module under test."
  value       = module.backup_standard_vault.arn
}

output "air_gapped_vault_arn" {
  description = "ARN of the logically air-gapped Backup Vault created by the module under test."
  value       = module.backup_logically_air_gapped_vault.arn
}

output "backup_plan_id" {
  description = "ID of the Backup Plan created by the module under test."
  value       = module.backup_plan.id
}

output "backup_selection_id" {
  description = "ID of the Backup Selection created by the module under test."
  value       = module.backup_selection.id
}
