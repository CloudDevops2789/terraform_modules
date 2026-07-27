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

# Backup rules define when backups run and
# how long recovery points are retained.
#
# One AWS Backup Rule is created for each
# object in the map.
#
# Example:
#
# rules = {
#
#   daily = {
#
#     schedule = "cron(0 5 ? * * *)"
#
#     lifecycle = {
#       delete_after = 30
#     }
#
#   }
#
# }
#
variable "rules" {

  description = "Backup rules for the Backup Plan."

  type = map(object({

    schedule = string

    start_window = optional(number, 60)

    completion_window = optional(number, 180)

    lifecycle = object({

      delete_after = number

      cold_storage_after = optional(number)

    })

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