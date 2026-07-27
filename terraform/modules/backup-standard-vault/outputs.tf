############################################
# Backup Vault Outputs
############################################

# The ID of the Backup Vault.
output "id" {

  description = "The ID of the Backup Vault."

  value = aws_backup_vault.this.id

}

# The ARN of the Backup Vault.
output "arn" {

  description = "The ARN of the Backup Vault."

  value = aws_backup_vault.this.arn

}

# The name of the Backup Vault.
output "name" {

  description = "The name of the Backup Vault."

  value = aws_backup_vault.this.name

}

# Number of recovery points currently stored
# in the Backup Vault.
#
# This value is managed by AWS and changes as
# backups are created or expire.
#
output "recovery_points" {

  description = "Number of recovery points in the Backup Vault."

  value = aws_backup_vault.this.recovery_points

}