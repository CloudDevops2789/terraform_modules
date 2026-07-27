############################################
# AWS Backup Plan
############################################

# Creates an AWS Backup Plan.
#
# A Backup Plan defines one or more backup
# rules that determine:
#
# - When backups run
# - Which Backup Vault stores them
# - How long recovery points are retained
#
resource "aws_backup_plan" "this" {

  name = var.name

  ##########################################
  # Backup Rules
  ##########################################

  dynamic "rule" {

    for_each = var.rules

    content {

      rule_name = rule.key

      target_vault_name = var.backup_vault_name

      schedule = rule.value.schedule

      start_window = rule.value.start_window

      completion_window = rule.value.completion_window

      ######################################
      # Lifecycle
      ######################################

      lifecycle {

        delete_after = rule.value.lifecycle.delete_after

        cold_storage_after = rule.value.lifecycle.cold_storage_after

      }

    }

  }

  ##########################################
  # Tags
  ##########################################

  tags = var.tags

}