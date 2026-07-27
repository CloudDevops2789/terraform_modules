############################################
# Backup Vault Configuration
############################################

# The name of the AWS Backup Vault.
#
# The name must be unique within the AWS account
# and Region.
#
variable "name" {

  description = "Name of the AWS Backup Vault."

  type = string

}

############################################
# Encryption
############################################

# ARN of the KMS key used to encrypt recovery points.
#
# If omitted, AWS Backup uses the default AWS managed
# KMS key for the service.
#
variable "kms_key_arn" {

  description = "Optional customer-managed KMS key ARN."

  type = string

  default = null

}

############################################
# Vault Management
############################################

# Controls whether Terraform is allowed to delete
# the backup vault even if it still contains recovery
# points.
#
# WARNING:
# Enabling this option may permanently delete
# recovery points during infrastructure destruction.
#
variable "force_destroy" {

  description = "Allow deletion of a backup vault containing recovery points."

  type = bool

  default = false

}

############################################
# Resource Tags
############################################

# Tags applied to all resources created by
# this module.
#
variable "tags" {

  description = "Tags applied to the Backup Vault."

  type = map(string)

  default = {}

}