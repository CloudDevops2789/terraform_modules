############################################
# Backup Plan Configuration
############################################

# Name of the AWS Backup Plan.
#
# This name is displayed in the AWS Backup
# console and uniquely identifies the plan.
#
variable "name" {

  description = "Name of the Backup Plan."

  type = string

}

############################################
# Backup Vault
############################################

# Name of the Backup Vault where recovery
# points created by this plan will be stored.
#
variable "backup_vault_name" {

  description = "Name of the Backup Vault."

  type = string

}

############################################
# Backup Rules
############################################

# Collection of backup rules that define
# the backup schedule, retention policy,
# and optional copy actions for the
# Backup Plan.
#
# Multiple rules (for example, daily,
# weekly, and monthly) can be defined
# within a single Backup Plan.
#
variable "rules" {

  description = "Backup rules for the AWS Backup Plan."

  type = map(object({

    ########################################
    # Backup Schedule
    ########################################

    schedule = string

    start_window = optional(number)

    completion_window = optional(number)

    ########################################
    # Backup Lifecycle
    ########################################

    lifecycle = optional(object({

      cold_storage_after = optional(number)

      delete_after = optional(number)

    }))

    ########################################
    # Backup Copy Actions
    ########################################

    copy_actions = optional(map(object({

      destination_vault_arn = string

      ######################################
      # Copy Lifecycle
      ######################################

      lifecycle = optional(object({

        cold_storage_after = optional(number)

        delete_after = optional(number)

      }))

    })))

  }))

}
############################################
# Resource Tags
############################################

variable "tags" {

  description = "Tags applied to the Backup Plan."

  type = map(string)

  default = {}

}