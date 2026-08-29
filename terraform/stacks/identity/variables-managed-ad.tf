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
  description = "Logical Platform VPC keys permitted to use native Active Directory services. The directory placement VPC is excluded from additive rules because AWS owns its baseline rules."
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

variable "managed_ad_dns_resolver" {
  description = "Optional private Route 53 Resolver integration for the managed directory DNS namespace."

  type = object({
    enabled = optional(bool, false)

    endpoint_name       = optional(string, "managed-ad-private-dns")
    rule_name           = optional(string, "managed-ad-domain")
    security_group_name = optional(string)

    vpc_key               = string
    subnet_group          = string
    required_subnet_count = optional(number, 2)

    associated_vpc_keys = set(string)

    query_log_config_id = optional(string)
    query_log_vpc_keys  = optional(set(string), [])
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.managed_ad_dns_resolver == null ||
      try(
        !var.managed_ad_dns_resolver.enabled ||
        (
          var.managed_ad_enabled &&
          var.managed_ad_configuration != null &&
          var.platform_contract != null &&
          length(trimspace(var.managed_ad_dns_resolver.endpoint_name)) > 0 &&
          length(trimspace(var.managed_ad_dns_resolver.rule_name)) > 0 &&
          (
            var.managed_ad_dns_resolver.security_group_name == null
            ? true
            : length(trimspace(var.managed_ad_dns_resolver.security_group_name)) > 0
          ) &&
          length(trimspace(var.managed_ad_dns_resolver.vpc_key)) > 0 &&
          length(trimspace(var.managed_ad_dns_resolver.subnet_group)) > 0 &&
          var.managed_ad_dns_resolver.required_subnet_count >= 2 &&
          floor(var.managed_ad_dns_resolver.required_subnet_count) == var.managed_ad_dns_resolver.required_subnet_count &&
          length(var.managed_ad_dns_resolver.associated_vpc_keys) > 0 &&
          (
            var.managed_ad_dns_resolver.query_log_config_id == null
            ? length(var.managed_ad_dns_resolver.query_log_vpc_keys) == 0
            : length(trimspace(var.managed_ad_dns_resolver.query_log_config_id)) > 0
          )
        ),
        false
      )
    )
    error_message = "Enabled managed_ad_dns_resolver requires Managed AD, valid private endpoint placement, at least two subnets, associated VPCs, and a query-log configuration when query-log VPCs are supplied."
  }

  validation {
    condition = (
      var.managed_ad_dns_resolver == null ||
      try(
        !var.managed_ad_dns_resolver.enabled ||
        var.platform_contract == null ||
        (
          contains(keys(var.platform_contract.vpc_ids), var.managed_ad_dns_resolver.vpc_key) &&
          contains(
            keys(var.platform_contract.subnet_ids_by_group[var.managed_ad_dns_resolver.vpc_key]),
            var.managed_ad_dns_resolver.subnet_group
          ) &&
          length(
            var.platform_contract.subnet_ids_by_group[
              var.managed_ad_dns_resolver.vpc_key
              ][
              var.managed_ad_dns_resolver.subnet_group
            ]
          ) >= var.managed_ad_dns_resolver.required_subnet_count &&
          alltrue([
            for vpc_key in setunion(
              var.managed_ad_dns_resolver.associated_vpc_keys,
              var.managed_ad_dns_resolver.query_log_vpc_keys
            ) :
            contains(keys(var.platform_contract.vpc_ids), vpc_key)
          ])
        ),
        false
      )
    )
    error_message = "managed_ad_dns_resolver must resolve entirely through existing Platform VPC and subnet-group keys."
  }
}
