##################################################################################################
# Common Environment
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
# Platform Dependency
##################################################################################################
#
# Source:
#   Platform output.inspection_contract
#     -> AAP read_dependency.yml
#     -> runtime_variables.yml
#     -> var.inspection_contract
#
# Platform owns the VPC/TGW topology and approved directional connectivity.
# Inspection consumes only the identifiers and CIDRs required to place Network
# Firewall and construct firewall-dependent routing.
##################################################################################################

variable "inspection_contract" {
  description = "Platform-owned topology contract required by the Inspection stack."

  type = object({
    transit_gateway_id = string
    account_cidr_block = string

    connectivity = map(object({
      source_vpc_key      = string
      destination_vpc_key = string
    }))

    inspection_vpc = object({
      key                           = string
      vpc_id                        = string
      cidr_block                    = string
      transit_gateway_attachment_id = optional(string)

      firewall_subnets_by_az = map(object({
        subnet_id      = string
        cidr_block     = string
        route_table_id = string
      }))

      transit_gateway_subnets_by_az = map(object({
        subnet_id      = string
        cidr_block     = string
        route_table_id = string
      }))
    })

    spoke_vpcs = map(object({
      vpc_id                         = string
      cidr_block                     = string
      transit_gateway_attachment_id  = string
      transit_gateway_route_table_id = string
    }))
  })
}

##################################################################################################
# Persistent Dependency
##################################################################################################
#
# Source:
#   Persistent output.network_firewall_logging_kms_key_arn
#     -> AAP read_dependency.yml
#     -> runtime_variables.yml
#     -> var.persistent_resources
##################################################################################################

variable "persistent_resources" {
  description = "Persistent resources consumed by the Inspection stack."

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

##################################################################################################
# Naming
##################################################################################################
#
# These are Git-controlled desired-state values. They intentionally mirror the
# naming algorithm currently used by Platform so that transferring existing
# Network Firewall resources does not change their AWS names.
##################################################################################################

variable "naming" {
  description = "Naming components used to derive Inspection resource names."

  type = object({
    organization             = string
    project                  = string
    project_display_name     = string
    environment              = string
    environment_display_name = string
    region_code              = optional(string)
    suffix                   = optional(string)
  })

  nullable = false

  validation {
    condition = alltrue([
      length(trimspace(var.naming.organization)) > 0,
      length(trimspace(var.naming.project)) > 0,
      length(trimspace(var.naming.project_display_name)) > 0,
      length(trimspace(var.naming.environment)) > 0,
      length(trimspace(var.naming.environment_display_name)) > 0,
      var.naming.region_code == null ? true : length(trimspace(var.naming.region_code)) > 0,
      var.naming.suffix == null ? true : length(trimspace(var.naming.suffix)) > 0,
    ])

    error_message = "Naming components must be non-empty when supplied."
  }
}

variable "resource_name_overrides" {
  description = "Optional exact names for Inspection-owned resources. Null values use derived names."

  type = object({
    network_firewall                  = optional(string)
    network_firewall_policy           = optional(string)
    network_firewall_rule_group       = optional(string)
    network_firewall_log_group_prefix = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name in values(var.resource_name_overrides) :
      name == null ? true : length(trimspace(name)) > 0
    ])

    error_message = "Inspection resource-name overrides must be null or non-empty strings."
  }
}

##################################################################################################
# Organization Tags
##################################################################################################

variable "organization_tag_key_prefix" {
  description = "Prefix used when constructing optional standard organization tag keys."
  type        = string
  default     = "org_"
  nullable    = false

  validation {
    condition = (
      trimspace(var.organization_tag_key_prefix) == var.organization_tag_key_prefix &&
      length(var.organization_tag_key_prefix) > 0 &&
      length(var.organization_tag_key_prefix) <= 64 &&
      !startswith(lower(var.organization_tag_key_prefix), "aws:") &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]+$",
        var.organization_tag_key_prefix
      ))
    )

    error_message = "organization_tag_key_prefix must use portable AWS tag-key characters: letters, numbers, spaces, _ . : / = + - @, and must not use the reserved aws: prefix."
  }
}

variable "org_it_cost_center" {
  description = "Optional organization IT cost-center tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_it_cost_center == null ? true : (
      length(var.org_it_cost_center) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_it_cost_center
      ))
    )

    error_message = "org_it_cost_center must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_department" {
  description = "Optional organization department tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_department == null ? true : (
      length(var.org_department) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_department
      ))
    )

    error_message = "org_department must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @. Characters such as & and comma are not portable to IAM tags."
  }
}

variable "org_cmdb_calculated_app" {
  description = "Optional organization CMDB calculated-application tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_cmdb_calculated_app == null ? true : (
      length(var.org_cmdb_calculated_app) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_cmdb_calculated_app
      ))
    )

    error_message = "org_cmdb_calculated_app must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_business_criticality" {
  description = "Optional organization business-criticality tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_business_criticality == null ? true : (
      length(var.org_business_criticality) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_business_criticality
      ))
    )

    error_message = "org_business_criticality must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_environment" {
  description = "Optional organization environment tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_environment == null ? true : (
      length(var.org_environment) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_environment
      ))
    )

    error_message = "org_environment must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_data_classification" {
  description = "Optional organization data-classification tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_data_classification == null ? true : (
      length(var.org_data_classification) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_data_classification
      ))
    )

    error_message = "org_data_classification must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_project_name" {
  description = "Optional organization project-name tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_project_name == null ? true : (
      length(var.org_project_name) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_project_name
      ))
    )

    error_message = "org_project_name must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_managed_by" {
  description = "Optional organization managed-by tag value."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.org_managed_by == null ? true : (
      length(var.org_managed_by) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        var.org_managed_by
      ))
    )

    error_message = "org_managed_by must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @."
  }
}

variable "org_additional_tags" {
  description = "Optional additional AWS resource tags. Keys do not require the organization prefix and may override optional standard organization tags."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.org_additional_tags) :
      length(key) > 0 &&
      length(key) <= 128 &&
      !startswith(lower(key), "aws:") &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]+$",
        key
      ))
    ])

    error_message = "Additional tag keys must be 1-128 characters, must not use the reserved aws: prefix, and must use portable AWS tag-key characters: letters, numbers, spaces, _ . : / = + - @."
  }

  validation {
    condition = alltrue([
      for value in values(var.org_additional_tags) :
      length(value) <= 256 &&
      can(regex(
        "^[\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*$",
        value
      ))
    ])

    error_message = "Additional tag values must be no longer than 256 characters and must use portable AWS tag-value characters: letters, numbers, spaces, _ . : / = + - @. Characters such as & and comma are not portable to IAM tags."
  }
}

##################################################################################################
# Network Firewall Policy
##################################################################################################
#
# This policy belongs to Inspection rather than Platform. Logical zone names
# remain portable; their CIDRs are resolved from var.inspection_contract.
##################################################################################################

variable "network_firewall_rules" {
  description = "Ordered AWS Network Firewall stateful rules evaluated using STRICT_ORDER."

  type = list(object({
    action           = string
    protocol         = string
    source_zone      = string
    source_port      = optional(string, "any")
    destination_zone = string
    destination_port = optional(string, "any")
    description      = string
    sid              = number
    enabled          = optional(bool, true)
  }))

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["pass", "drop"], rule.action)
    ])

    error_message = "Each Network Firewall rule action must be either 'pass' or 'drop'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "tcp", "udp", "icmp"], rule.protocol)
    ])

    error_message = "Each Network Firewall rule protocol must be ip, tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.source_zone
      ) &&
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.destination_zone
      )
    ])

    error_message = "Firewall rule zones must be recovery_access, core_recovery, protected_data, or any."
  }

  validation {
    condition = (
      length(distinct([
        for rule in var.network_firewall_rules : rule.sid
      ])) == length(var.network_firewall_rules)
    )

    error_message = "Every Network Firewall rule SID must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      rule.sid > 0 && rule.sid == floor(rule.sid)
    ])

    error_message = "Every Network Firewall rule SID must be a positive whole number."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.network_firewall_rules : [
        for port in [rule.source_port, rule.destination_port] :
        port == "any" || (
          can(regex("^[0-9]{1,5}(:[0-9]{1,5})?$", port)) &&
          try(
            tonumber(split(":", port)[0]) >= 0 &&
            tonumber(split(":", port)[0]) <= 65535,
            false
          ) &&
          (
            length(split(":", port)) == 1
            ? true
            : try(
              tonumber(split(":", port)[1]) >= 0 &&
              tonumber(split(":", port)[1]) <= 65535 &&
              tonumber(split(":", port)[0]) <= tonumber(split(":", port)[1]),
              false
            )
          )
        )
      ]
    ]))

    error_message = "Firewall ports must be 'any', a port from 0 to 65535, or an ascending range such as '1024:65535'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "icmp"], rule.protocol)
      ? rule.source_port == "any" && rule.destination_port == "any"
      : true
    ])

    error_message = "Firewall rules using protocol 'ip' or 'icmp' must use 'any' for source_port and destination_port."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      length(trimspace(rule.description)) > 0 &&
      !strcontains(rule.description, "\"") &&
      !strcontains(rule.description, "\\") &&
      !strcontains(rule.description, ";") &&
      !strcontains(rule.description, "\n") &&
      !strcontains(rule.description, "\r")
    ])

    error_message = "Firewall rule descriptions must not be empty or contain double quotes, backslashes, semicolons, or newline characters."
  }
}

##################################################################################################
# Network Firewall Logging
##################################################################################################

variable "network_firewall_logging_enabled" {
  description = "Enable Network Firewall CloudWatch logging. A customer-managed KMS key is optional."
  type        = bool
  default     = false
}
