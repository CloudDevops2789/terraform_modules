##################################################################################################
# Persistent Resources Integration
##################################################################################################

variable "network_firewall_logging_enabled" {
  description = "Enable Network Firewall CloudWatch logging. A customer-managed KMS key is optional."
  type        = bool
  default     = false
}

variable "persistent_resources" {
  description = "Optional references to persistent IRE resources consumed by the Platform stack."

  type = object({
    network_firewall_logging_kms_key_arn = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = (
      try(var.persistent_resources.network_firewall_logging_kms_key_arn, null) == null ||
      can(regex(
        "^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/",
        var.persistent_resources.network_firewall_logging_kms_key_arn
      ))
    )

    error_message = "When supplied, persistent_resources.network_firewall_logging_kms_key_arn must be a valid KMS key ARN."
  }
}
