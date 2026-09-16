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
#            |
#            v
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
