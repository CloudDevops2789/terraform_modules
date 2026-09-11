variable "aws_region" {
  description = "AWS Region in which the persistent IRE resources are deployed."
  type        = string
}

variable "name_prefix" {
  description = "Enterprise resource-name prefix for persistent IRE resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "backup_vaults_enabled" {
  description = "Create and manage the persistent standard and logically air-gapped AWS Backup vaults."
  type        = bool
  default     = false
}

variable "network_firewall_logging_kms_enabled" {
  description = "Create and manage a customer-managed KMS key for Network Firewall CloudWatch log encryption."
  type        = bool
  default     = false
}

variable "air_gapped_min_retention_days" {
  description = "Minimum retention period for the logically air-gapped vault when backup_vaults_enabled is true."
  type        = number
  default     = 30
}

variable "air_gapped_max_retention_days" {
  description = "Maximum retention period for the logically air-gapped vault when backup_vaults_enabled is true."
  type        = number
  default     = 365

  validation {
    condition     = var.air_gapped_max_retention_days >= var.air_gapped_min_retention_days
    error_message = "air_gapped_max_retention_days must be greater than or equal to the minimum retention period."
  }
}

variable "kms_key_administrators" {
  description = "Stable IAM role/user ARNs allowed to administer the optional logging KMS key. Do not supply STS assumed-role session ARNs."
  type        = list(string)
  default     = []

  validation {
    condition = (
      !var.network_firewall_logging_kms_enabled ||
      (
        length(var.kms_key_administrators) > 0 &&
        alltrue([
          for arn in var.kms_key_administrators :
          can(regex("^arn:[^:]+:iam::[0-9]{12}:(role|user)/", arn))
        ])
      )
    )

    error_message = "When network_firewall_logging_kms_enabled=true, kms_key_administrators must contain at least one stable IAM role or user ARN."
  }
}

variable "network_firewall_log_group_prefix" {
  description = "CloudWatch Logs prefix authorized to use the optional Network Firewall logging KMS key."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.network_firewall_logging_kms_enabled ||
      try(
        startswith(var.network_firewall_log_group_prefix, "/aws/network-firewall/"),
        false
      )
    )

    error_message = "When network_firewall_logging_kms_enabled=true, network_firewall_log_group_prefix must start with /aws/network-firewall/."
  }
}


################################################################################
# Organization Tagging Inputs
#
# These values are combined in locals.tf:
#
#   var.organization_tag_key_prefix
#   var.org_*
#   var.org_additional_tags
#            |
#            v
#   local.org_default_tags
#            |
#            v
#   local.org_tags
#
# local.org_tags is then applied through provider.tf default_tags and may also
# be merged with resource-specific tags in main.tf.
#
# In AAP execution these organization values come from the approved environment
# inventory through terraform_environment_variables_by_stack. They are not
# intended to be arbitrary Job Template inputs.
################################################################################

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
