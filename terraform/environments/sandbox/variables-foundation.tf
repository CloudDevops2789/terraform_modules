##################################################################################################
# Optional Persistent Foundation Integrations
##################################################################################################

variable "backup_integration_enabled" {
  description = "Enable Sandbox AWS Backup plan, IAM role, selection, and integration with persistent Foundation backup vaults."
  type        = bool
  default     = false
}

variable "network_firewall_logging_enabled" {
  description = "Enable Network Firewall CloudWatch logging using the persistent Foundation logging KMS key."
  type        = bool
  default     = false
}

variable "foundation_resources" {
  description = "Optional references to persistent IRE Foundation resources consumed only when the corresponding integration is enabled."

  type = object({
    standard_backup_vault_name           = optional(string)
    air_gapped_backup_vault_arn          = optional(string)
    network_firewall_logging_kms_key_arn = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = (
      !var.backup_integration_enabled ||
      (
        try(length(trimspace(var.foundation_resources.standard_backup_vault_name)) > 0, false) &&
        can(regex(
          "^arn:[^:]+:backup:[^:]+:[0-9]{12}:backup-vault:",
          coalesce(var.foundation_resources.air_gapped_backup_vault_arn, "")
        ))
      )
    )

    error_message = "When backup_integration_enabled=true, provide foundation_resources.standard_backup_vault_name and a valid air_gapped_backup_vault_arn."
  }

  validation {
    condition = (
      !var.network_firewall_logging_enabled ||
      can(regex(
        "^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/",
        coalesce(var.foundation_resources.network_firewall_logging_kms_key_arn, "")
      ))
    )

    error_message = "When network_firewall_logging_enabled=true, provide a valid foundation_resources.network_firewall_logging_kms_key_arn."
  }
}
