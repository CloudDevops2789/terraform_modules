##################################################################################################
# AWS Managed Microsoft AD Variables
##################################################################################################

variable "managed_ad_enabled" {
  description = "Whether the Identity stack creates AWS Managed Microsoft AD."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.managed_ad_enabled ||
      (
        var.managed_ad_configuration != null &&
        var.identity_placement != null &&
        var.platform_contract != null &&
        nonsensitive(var.managed_ad_password != null)
      )
    )
    error_message = "Enabling Managed AD requires approved configuration, password, placement, and Platform contract inputs."
  }
}

variable "managed_ad_configuration" {
  description = "Git-controlled, non-sensitive AWS Managed Microsoft AD configuration."

  type = object({
    domain_name = string
    short_name  = optional(string)
    edition     = optional(string, "Standard")
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.managed_ad_configuration == null ||
      try(
        length(trimspace(var.managed_ad_configuration.domain_name)) > 0 &&
        strcontains(var.managed_ad_configuration.domain_name, ".") &&
        length(regexall("\\s", var.managed_ad_configuration.domain_name)) == 0 &&
        contains(["Standard", "Enterprise"], var.managed_ad_configuration.edition),
        false
      )
    )
    error_message = "managed_ad_configuration requires a valid FQDN and Standard or Enterprise edition."
  }
}

variable "managed_ad_client_vpc_keys" {
  description = "Logical Platform VPC keys permitted to use native Active Directory services."
  type        = set(string)
  default     = []

  validation {
    condition = (
      var.platform_contract == null ||
      alltrue([
        for vpc_key in var.managed_ad_client_vpc_keys :
        contains(keys(var.platform_contract.vpc_cidrs), vpc_key)
      ])
    )
    error_message = "Every managed_ad_client_vpc_keys entry must resolve through the Platform contract."
  }
}

variable "managed_ad_password" {
  description = "Bootstrap password for the AWS Managed Microsoft AD Admin account. Supply only through an approved AAP secret."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
