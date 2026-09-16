################################################################################
# Identity Stack Inputs
#
# This file contains the complete typed input contract for the Identity root.
#
# Input sources:
#
#   common-tags.tfvars
#       -> organization tagging variables
#
#   identity.tfvars
#       -> Managed AD enablement, configuration, placement, and DNS settings
#
#   AAP cross-stack dependency contract
#       -> var.platform_contract
#
#   AAP credential
#       -> var.managed_ad_password
#
# Terraform does not read the Platform stack directly. AAP reads the approved
# Platform output contract from Platform state and injects it as
# var.platform_contract before Terraform planning.
################################################################################

##################################################################################################
# Common Environment Variables
##################################################################################################

variable "aws_region" {
  description = "AWS Region for this environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}


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
    domain_name                  = string
    short_name                   = optional(string)
    edition                      = optional(string, "Standard")
    enable_directory_data_access = optional(bool, false)
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


##################################################################################################
# Generic Platform Contract
##################################################################################################

variable "platform_contract" {
  description = "Topology-agnostic Platform values available to the Identity stack."

  type = object({
    vpc_ids   = map(string)
    vpc_cidrs = map(string)

    subnet_ids_by_group = map(
      map(list(string))
    )
  })

  default  = null
  nullable = true
}

variable "identity_placement" {
  description = "Configuration-driven placement of Identity services within the Platform topology."

  type = object({
    vpc_key               = string
    subnet_group          = string
    required_subnet_count = optional(number, 2)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.identity_placement == null ||
      (
        length(trimspace(var.identity_placement.vpc_key)) > 0 &&
        length(trimspace(var.identity_placement.subnet_group)) > 0 &&
        var.identity_placement.required_subnet_count > 0 &&
        floor(var.identity_placement.required_subnet_count) ==
        var.identity_placement.required_subnet_count
      )
    )

    error_message = "identity_placement must contain valid logical Platform selectors."
  }

  validation {
    condition = (
      var.platform_contract == null ||
      var.identity_placement == null ||
      try(
        contains(
          keys(var.platform_contract.vpc_ids),
          var.identity_placement.vpc_key
        ) &&
        contains(
          keys(
            var.platform_contract.subnet_ids_by_group[
              var.identity_placement.vpc_key
            ]
          ),
          var.identity_placement.subnet_group
        ) &&
        length(
          var.platform_contract.subnet_ids_by_group[
            var.identity_placement.vpc_key
            ][
            var.identity_placement.subnet_group
          ]
        ) >= var.identity_placement.required_subnet_count,
        false
      )
    )

    error_message = "identity_placement must resolve to an existing Platform VPC and enough subnets in the selected subnet group."
  }
}


##################################################################################################
# Organization Tagging Variables
##################################################################################################











##################################################################################################
# Portable environment naming
##################################################################################################

##################################################################################################
# Organization Resource Tags
##################################################################################################

variable "organization_tags" {
  description = "Organization-defined AWS resource tags. Keys and values are passed through exactly as supplied."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.organization_tags) :
      length(trimspace(key)) > 0 &&
      length(key) <= 128 &&
      !startswith(lower(key), "aws:")
    ])

    error_message = "Organization tag keys must be 1-128 characters and must not use the reserved aws: prefix."
  }

  validation {
    condition = alltrue([
      for value in values(var.organization_tags) :
      length(value) <= 256
    ])

    error_message = "Organization tag values must not exceed 256 characters."
  }
}
