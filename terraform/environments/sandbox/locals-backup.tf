locals {
  ##################################################################################################
  # Backup
  ##################################################################################################
  # Static AWS Backup configuration: vault/plan/role/selection display names,
  # retention windows, and the daily backup schedule. Vault ARNs, plan IDs,
  # and protected resource references are relationships between the backup
  # modules and remain in backup_vault.tf.
  backup = {
    standard_vault_name = local.resource_names.standard_backup_vault

    air_gapped_vault_name         = local.resource_names.air_gapped_backup_vault
    air_gapped_min_retention_days = 30
    air_gapped_max_retention_days = 365

    plan_name = local.resource_names.backup_plan

    role_name = local.resource_names.backup_role

    selection_name = local.resource_names.backup_selection

    plan_rules = {
      daily = {
        schedule          = "cron(0 5 ? * * *)"
        start_window      = 60
        completion_window = 180

        cold_storage_after = 30
        delete_after       = 365

        # Retention applied to the immutable copy in the air-gapped vault.
        cyber_recovery_delete_after = 365
      }
    }
  }
}
