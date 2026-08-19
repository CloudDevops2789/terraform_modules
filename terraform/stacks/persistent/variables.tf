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
