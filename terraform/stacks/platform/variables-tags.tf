##################################################################################################
# Organization Tagging Variables
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
# Portable environment naming
##################################################################################################
