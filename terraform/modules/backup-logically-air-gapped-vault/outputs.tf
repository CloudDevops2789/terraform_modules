############################################
# Logically Air-Gapped Backup Vault Outputs
############################################

output "id" {

  description = "The ID of the logically air-gapped backup vault."

  value = aws_backup_logically_air_gapped_vault.this.id

}

output "arn" {

  description = "The ARN of the logically air-gapped backup vault."

  value = aws_backup_logically_air_gapped_vault.this.arn

}

output "name" {

  description = "The name of the logically air-gapped backup vault."

  value = aws_backup_logically_air_gapped_vault.this.name

}