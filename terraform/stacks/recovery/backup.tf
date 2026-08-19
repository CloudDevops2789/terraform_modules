##################################################################################################
# Recovery Backup Policy
##################################################################################################
# Backup vaults are persistent IRE persistent resources and are intentionally
# owned by a separate Terraform state. This disposable recovery environment
# owns only the backup policy, execution role, and workload selection.
#
# Backup integration is disabled by default until the protected workload scope,
# RPO, retention, and copy requirements are approved.

############################################
# Backup Plan
############################################

# Defines how AWS Backup protects the
# recovery environment.
#
# The Backup Plan determines when backups
# are created, how long they are retained,
# and whether recovery points are copied
# to additional Backup Vaults for
# cyber recovery.
# Purpose: Creates the backup schedule, lifecycle settings, and copy actions.
# Change when: Change timing or retention only when RPO and retention requirements change.
module "backup_plan" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-plan"

  name = local.backup.plan_name

  backup_vault_name = var.persistent_resources.standard_backup_vault_name

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

          destination_vault_arn = var.persistent_resources.air_gapped_backup_vault_arn

          lifecycle = {

            delete_after = local.backup.plan_rules.daily.cyber_recovery_delete_after

          }

        }

      }

    }

  }

  tags = local.org_tags

}

############################################
# Backup IAM Role
############################################

# Creates the IAM Role assumed by AWS Backup
# to perform backup and restore operations.
#
# The role includes the required trust
# relationship and managed IAM policies
# that allow AWS Backup to protect and
# recover supported AWS resources.
#
# Purpose: Creates the IAM role assumed by AWS Backup.
# Change when: Change permissions or trust only when protected resource types or governance requirements change.
module "backup_role" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-role"

  name = local.backup.role_name

  tags = local.org_tags

}

############################################
# Backup Selection
############################################

# Associates AWS resources with the
# Backup Plan.
#
# Only resources included in this
# selection are protected by AWS Backup.
# Workload protection is selected through the configuration-driven
# recovery_workloads backup_enabled attribute.
# Purpose: Associates the selected Sandbox resources with the backup plan.
# Change when: Change protected resource ARNs only when backup scope changes.
module "backup_selection" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-selection"

  name = local.backup.selection_name

  backup_plan_id = module.backup_plan[0].id

  iam_role_arn = module.backup_role[0].arn

  resources = [
    for workload_key, instance_arn in module.ec2.instance_arns :
    instance_arn
    if var.recovery_workloads[workload_key].backup_enabled
  ]

  tags = local.org_tags

}
