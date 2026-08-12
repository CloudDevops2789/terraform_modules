##################################################################################################
# Persistent Foundation References
##################################################################################################

variable "foundation_resources" {
  description = "References to persistent IRE foundation resources that are not owned by the disposable Sandbox state."

  type = object({
    standard_backup_vault_name           = string
    air_gapped_backup_vault_arn          = string
    network_firewall_logging_kms_key_arn = string
  })

  validation {
    condition = (
      length(trimspace(var.foundation_resources.standard_backup_vault_name)) > 0 &&
      can(regex(
        "^arn:[^:]+:backup:[^:]+:[0-9]{12}:backup-vault:",
        var.foundation_resources.air_gapped_backup_vault_arn
      )) &&
      can(regex(
        "^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/",
        var.foundation_resources.network_firewall_logging_kms_key_arn
      ))
    )

    error_message = "foundation_resources must contain a valid backup vault name, air-gapped vault ARN, and KMS key ARN."
  }
}
