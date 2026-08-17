locals {
  ##################################################################################################
  # AWS Backup
  ##################################################################################################

  backup = {
    plan_name      = local.resource_names.backup_plan
    role_name      = local.resource_names.backup_role
    selection_name = local.resource_names.backup_selection

    plan_rules = {
      daily = {
        schedule          = "cron(0 5 ? * * *)"
        start_window      = 60
        completion_window = 180

        cold_storage_after = 30
        delete_after       = 365

        cyber_recovery_delete_after = 365
      }
    }
  }
}
