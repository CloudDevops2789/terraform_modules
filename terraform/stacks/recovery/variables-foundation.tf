##################################################################################################
# Foundation Backup Integration
##################################################################################################

variable "backup_integration_enabled" {
  description = "Enable Recovery-stack AWS Backup plan, role, and configuration-driven workload selection using persistent Foundation vaults."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.backup_integration_enabled ||
      (
        var.demo_ec2_enabled &&
        anytrue([
          for workload in values(var.recovery_workloads) :
          workload.backup_enabled
        ])
      )
    )

    error_message = "When backup integration is enabled, demo EC2 must be enabled and at least one Recovery workload must have backup_enabled=true."
  }
}

variable "foundation_resources" {
  description = "Persistent Foundation resources consumed by Recovery backup integration."

  type = object({
    standard_backup_vault_name  = optional(string)
    air_gapped_backup_vault_arn = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = (
      !var.backup_integration_enabled ||
      (
        try(
          length(
            trimspace(
              var.foundation_resources.standard_backup_vault_name
            )
          ) > 0,
          false
        ) &&
        can(regex(
          "^arn:[^:]+:backup:[^:]+:[0-9]{12}:backup-vault:",
          coalesce(
            var.foundation_resources.air_gapped_backup_vault_arn,
            ""
          )
        ))
      )
    )

    error_message = "When backup integration is enabled, provide the standard Backup vault name and a valid air-gapped Backup vault ARN."
  }
}
