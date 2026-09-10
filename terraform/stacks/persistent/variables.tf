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
#   local.org_required_tags
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
  description = "Prefix applied to mandatory organization tag keys. Reusable environments default to org_; private organization configuration may select an approved alternative."
  type        = string
  default     = "org_"
  nullable    = false

  validation {
    condition = (
      trimspace(var.organization_tag_key_prefix) == var.organization_tag_key_prefix &&
      length(var.organization_tag_key_prefix) > 0 &&
      length(var.organization_tag_key_prefix) <= 64 &&
      !startswith(lower(var.organization_tag_key_prefix), "aws:")
    )
    error_message = "organization_tag_key_prefix must be 1-64 characters, contain no surrounding whitespace, and must not use the reserved aws: prefix."
  }
}

variable "org_it_cost_center" {
  description = "Organization-approved IT cost center associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_it_cost_center)) > 0
    error_message = "org_it_cost_center must not be empty."
  }
}

variable "org_department" {
  description = "Organization-approved department associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_department)) > 0
    error_message = "org_department must not be empty."
  }
}

variable "org_cmdb_calculated_app" {
  description = "Organization-approved CMDB calculated application associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_cmdb_calculated_app)) > 0
    error_message = "org_cmdb_calculated_app must not be empty."
  }
}

variable "org_business_criticality" {
  description = "Organization-approved business criticality associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_business_criticality)) > 0
    error_message = "org_business_criticality must not be empty."
  }
}

variable "org_environment" {
  description = "Organization-approved environment classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_environment)) > 0
    error_message = "org_environment must not be empty."
  }
}

variable "org_data_classification" {
  description = "Organization-approved data classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_data_classification)) > 0
    error_message = "org_data_classification must not be empty."
  }
}

variable "org_project_name" {
  description = "Organization-approved project name associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_project_name)) > 0
    error_message = "org_project_name must not be empty."
  }
}

variable "org_managed_by" {
  description = "Organization-approved identifier for the system or team managing the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_managed_by)) > 0
    error_message = "org_managed_by must not be empty."
  }
}

variable "org_additional_tags" {
  description = "Additional organization-approved tags that do not redefine mandatory organization tags."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = length(setintersection(
      toset(keys(var.org_additional_tags)),
      toset([
        "${var.organization_tag_key_prefix}it_cost_center",
        "${var.organization_tag_key_prefix}department",
        "${var.organization_tag_key_prefix}cmdb_calculated_app",
        "${var.organization_tag_key_prefix}business_criticality",
        "${var.organization_tag_key_prefix}environment",
        "${var.organization_tag_key_prefix}data_classification",
        "${var.organization_tag_key_prefix}project_name",
        "${var.organization_tag_key_prefix}managed_by",
      ])
    )) == 0
    error_message = "org_additional_tags must not redefine mandatory organization tag keys."
  }

  validation {
    condition     = alltrue([for key in keys(var.org_additional_tags) : startswith(key, var.organization_tag_key_prefix)])
    error_message = "Every org_additional_tags key must start with organization_tag_key_prefix."
  }
}
