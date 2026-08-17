##################################################################################################
# Persistent Foundation Integration
##################################################################################################

variable "network_firewall_logging_enabled" {
  description = "Enable Network Firewall CloudWatch logging using the persistent Foundation logging KMS key."
  type        = bool
  default     = false
}

variable "foundation_resources" {
  description = "References to persistent IRE Foundation resources consumed by the Platform stack."

  type = object({
    network_firewall_logging_kms_key_arn = optional(string)
  })

  default  = {}
  nullable = false

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
