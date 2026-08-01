############################################################
# Key Configuration
############################################################

variable "description" {
  description = "Description of the KMS Customer Managed Key."
  type        = string
}

variable "alias" {
  description = "Alias for the KMS key. Do not include the 'alias/' prefix."
  type        = string

  validation {
    condition = (
      length(trimspace(var.alias)) > 0 &&
      !startswith(var.alias, "alias/")
    )

    error_message = "Alias cannot be empty and must not include the 'alias/' prefix."
  }
}

variable "is_enabled" {
  description = "Whether the KMS key is enabled when created."
  type        = bool
  default     = true
}

############################################################
# Key Lifecycle
############################################################

variable "enable_key_rotation" {
  description = "Enable automatic key rotation."
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Number of days between automatic key rotations. Applies only when enable_key_rotation is true."
  type        = number
  default     = null

  validation {
    condition = var.rotation_period_in_days == null ? true : (
      var.rotation_period_in_days >= 90 &&
      var.rotation_period_in_days <= 2560
    )

    error_message = "rotation_period_in_days must be between 90 and 2560 days."
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period, in days, before a scheduled key deletion."
  type        = number
  default     = 30

  validation {
    condition = (
      var.deletion_window_in_days >= 7 &&
      var.deletion_window_in_days <= 30
    )

    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "multi_region" {
  description = "Create the KMS key as a multi-Region primary key."
  type        = bool
  default     = false
}

############################################################
# Key Access
############################################################

variable "key_administrators" {
  description = "List of IAM principal ARNs granted administrative permissions to manage the KMS key."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.key_administrators) == length(distinct(var.key_administrators))
    error_message = "key_administrators must not contain duplicate principal ARNs."
  }
}

variable "key_user_principals" {
  description = "List of IAM principal ARNs granted permission to use the KMS key for cryptographic operations."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.key_user_principals) == length(distinct(var.key_user_principals))
    error_message = "key_user_principals must not contain duplicate principal ARNs."
  }
}

variable "bootstrap_current_caller" {
  description = "Grant the current Terraform caller administrative access when no explicit key administrators are provided."
  type        = bool
  default     = true
}

variable "acknowledge_root_only_administration" {
  description = "Required when no key administrators are configured and bootstrap_current_caller is false. Confirms that root-only administration is intentional."
  type        = bool
  default     = false
}

variable "additional_policy_documents" {
  description = "Additional IAM policy JSON documents merged into the default key policy using source_policy_documents. Statements must use unique SIDs that do not conflict with the module's reserved SIDs."
  type        = list(string)
  default     = []
}

############################################################
# Common Tags
############################################################

variable "tags" {
  description = "Tags to apply to the KMS resources."
  type        = map(string)
  default     = {}
}