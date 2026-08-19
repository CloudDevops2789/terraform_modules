##################################################################################################
# Persistent AWS Backup Resources
##################################################################################################
# These vaults intentionally outlive disposable IRE recovery-environment deployments.
# Recovery-environment destroy workflows must not own or attempt to delete these resources.

module "backup_standard_vault" {
  count = var.backup_vaults_enabled ? 1 : 0

  source = "../../modules/backup-standard-vault"

  name = local.standard_backup_vault_name

  # Retained recovery points must never be implicitly deleted by Terraform.
  force_destroy = false

  tags = local.org_tags
}

module "backup_logically_air_gapped_vault" {
  count = var.backup_vaults_enabled ? 1 : 0

  source = "../../modules/backup-logically-air-gapped-vault"

  name = local.air_gapped_backup_vault_name

  min_retention_days = var.air_gapped_min_retention_days
  max_retention_days = var.air_gapped_max_retention_days

  tags = local.org_tags
}
