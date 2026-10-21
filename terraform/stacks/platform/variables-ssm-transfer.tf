##################################################################################################
# Ansible over Systems Manager Transfer Channel
#
# amazon.aws.aws_ssm uses S3 as a transient module/file transport. Platform owns
# the supporting encrypted private bucket because it is part of the persistent
# IRE management plane rather than an individual Recovery workload lifecycle.
##################################################################################################

variable "ssm_transfer_bucket_enabled" {
  description = "Create the private transient S3 transfer channel used by Ansible over Systems Manager."
  type        = bool
  default     = false
}

variable "ssm_transfer_object_expiration_days" {
  description = "Number of days after which transient Ansible/SSM transfer objects expire."
  type        = number
  default     = 1

  validation {
    condition = (
      var.ssm_transfer_object_expiration_days >= 1 &&
      floor(var.ssm_transfer_object_expiration_days) ==
      var.ssm_transfer_object_expiration_days
    )

    error_message = "ssm_transfer_object_expiration_days must be a whole number greater than or equal to 1."
  }
}

variable "ssm_transfer_kms_key_administrators" {
  description = "Stable IAM principal ARNs permitted to administer the Ansible/SSM transfer KMS key."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "ssm_transfer_kms_key_users" {
  description = "Stable IAM principal ARNs permitted to use the Ansible/SSM transfer KMS key."
  type        = list(string)
  default     = []
  nullable    = false
}

##################################################################################################
# Guardrails
##################################################################################################

check "ssm_transfer_requires_management_plane" {
  assert {
    condition = (
      !var.ssm_transfer_bucket_enabled ||
      var.ssm_management_plane_enabled
    )

    error_message = "The Ansible/SSM transfer bucket requires the Platform SSM management plane to be enabled."
  }
}

check "ssm_transfer_requires_kms_administrator" {
  assert {
    condition = (
      !var.ssm_transfer_bucket_enabled ||
      length(var.ssm_transfer_kms_key_administrators) > 0
    )

    error_message = "At least one stable KMS administrator ARN is required when the Ansible/SSM transfer bucket is enabled."
  }
}
