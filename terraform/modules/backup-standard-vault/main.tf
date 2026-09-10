############################################
# AWS Backup Vault
############################################

# A Backup Vault is the logical container used by
# AWS Backup to store recovery points.
#
# Recovery points are created by Backup Plans and
# retained according to lifecycle policies.
#
# A vault may optionally use a customer-managed KMS
# key for encryption.
#
resource "aws_backup_vault" "this" {

  name = var.name

  kms_key_arn = var.kms_key_arn

  force_destroy = var.force_destroy

  tags = var.tags

}