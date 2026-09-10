############################################
# Logically Air-Gapped Backup Vault
############################################

# Creates an AWS Backup Logically
# Air-Gapped Vault.
#
# Recovery points copied into this vault
# are protected by immutable retention
# boundaries, helping defend against
# ransomware and accidental deletion.
#
resource "aws_backup_logically_air_gapped_vault" "this" {

  name = var.name

  min_retention_days = var.min_retention_days

  max_retention_days = var.max_retention_days

  encryption_key_arn = var.encryption_key_arn

  tags = var.tags

}