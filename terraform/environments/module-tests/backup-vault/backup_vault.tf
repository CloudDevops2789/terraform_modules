##################################################################################################
# Modules Under Test: backup-standard-vault, backup-logically-air-gapped-vault,
#                      backup-role, backup-plan, backup-selection
##################################################################################################
# These five modules are always deployed together - a plan needs a vault to
# write to, a role to assume, and a selection to know what to protect - so
# this environment validates the full backup composition, mirroring how
# sandbox uses them.

############################################
# Standard Backup Vault
############################################
module "backup_standard_vault" {

  source = "../../../modules/backup-standard-vault"

  name = local.backup.standard_vault_name

  tags = local.default_tags

}

############################################
# Logically Air-Gapped Backup Vault
############################################
module "backup_logically_air_gapped_vault" {

  source = "../../../modules/backup-logically-air-gapped-vault"

  name = local.backup.air_gapped_vault_name

  min_retention_days = local.backup.air_gapped_min_retention_days

  max_retention_days = local.backup.air_gapped_max_retention_days

  tags = local.default_tags

}

############################################
# Backup Plan
############################################
module "backup_plan" {

  source = "../../../modules/backup-plan"

  name = local.backup.plan_name

  backup_vault_name = module.backup_standard_vault.name

  rules = {

    daily = {

      schedule = local.backup.plan_rules.daily.schedule

      start_window = local.backup.plan_rules.daily.start_window

      completion_window = local.backup.plan_rules.daily.completion_window

      lifecycle = {

        cold_storage_after = local.backup.plan_rules.daily.cold_storage_after

        delete_after = local.backup.plan_rules.daily.delete_after

      }

      copy_actions = {

        cyber_recovery = {

          destination_vault_arn = module.backup_logically_air_gapped_vault.arn

          lifecycle = {

            delete_after = local.backup.plan_rules.daily.cyber_recovery_delete_after

          }

        }

      }

    }

  }

  tags = local.default_tags

}

############################################
# Backup IAM Role
############################################
module "backup_role" {

  source = "../../../modules/backup-role"

  name = local.backup.role_name

  tags = local.default_tags

}

############################################
# Backup Selection
############################################
module "backup_selection" {

  source = "../../../modules/backup-selection"

  name = local.backup.selection_name

  backup_plan_id = module.backup_plan.id

  iam_role_arn = module.backup_role.arn

  resources = [

    module.ec2.instance_arns["workload"] # the one supporting resource this test protects

  ]

  tags = local.default_tags

}
