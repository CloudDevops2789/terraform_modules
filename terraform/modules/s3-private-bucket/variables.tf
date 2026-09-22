variable "name" {
  description = "Globally unique name of the private S3 bucket."
  type        = string

  validation {
    condition = (
      length(var.name) >= 3 &&
      length(var.name) <= 63
    )
    error_message = "S3 bucket name must contain between 3 and 63 characters."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN used for default bucket encryption."
  type        = string

  validation {
    condition = can(regex(
      "^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$",
      var.kms_key_arn
    ))
    error_message = "kms_key_arn must be a valid KMS key ARN."
  }
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty bucket."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the S3 bucket."
  type        = map(string)
  default     = {}
}
