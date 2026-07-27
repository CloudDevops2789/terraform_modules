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

  ############################################
  # Backup Rules
  ############################################

  # A Backup Plan can contain one or more
  # backup rules.
  #
  # Each rule defines:
  #
  # - When backups are created.
  # - Which Backup Vault stores them.
  # - How long recovery points are retained.
  # - Whether recovery points are copied to
  #   additional Backup Vaults.
  #
  # Rules are provided as a map, allowing
  # multiple schedules (for example, daily,
  # weekly, and monthly) to be managed from
  # a single Backup Plan.
  #

  dynamic "rule" {

    for_each = var.rules

    content {

      rule_name = rule.key

      target_vault_name = var.backup_vault_name

      schedule = rule.value.schedule

      start_window = rule.value.start_window

      completion_window = rule.value.completion_window

      ######################################
      # Backup Rule Lifecycle
      ######################################

      # Defines the retention policy for
      # recovery points stored in the primary
      # Backup Vault.
      #
      # Recovery points can optionally be
      # transitioned to cold storage before
      # permanent deletion.
      #
      dynamic "lifecycle" {

        for_each = rule.value.lifecycle != null ? [rule.value.lifecycle] : []

        content {

          delete_after = lifecycle.value.delete_after

          cold_storage_after = lifecycle.value.cold_storage_after

        }

      }

      ######################################
      # Backup Copy Actions
      ######################################

      # Optionally copies recovery points
      # created by this rule to one or more
      # destination Backup Vaults.
      #
      # This is commonly used to replicate
      # backups from a Standard Backup Vault
      # to a Logically Air-Gapped Vault for
      # ransomware protection and disaster
      # recovery.
      #

      dynamic "copy_action" {

        for_each = rule.value.copy_actions != null ? rule.value.copy_actions : {}

        content {

          destination_vault_arn = copy_action.value.destination_vault_arn

          ##################################
          # Copy Lifecycle
          ##################################

          # Defines the retention policy for
          # recovery points stored in the
          # destination Backup Vault.
          #
          # The lifecycle of copied recovery
          # points is managed independently of
          # the source Backup Vault.
          #

          dynamic "lifecycle" {

            for_each = copy_action.value.lifecycle != null ? [copy_action.value.lifecycle] : []

            content {

              delete_after = lifecycle.value.delete_after

              cold_storage_after = lifecycle.value.cold_storage_after

            }

          }

        }

      }

    }

  }

  ##########################################
  # Tags
  ##########################################

  tags = var.tags

}