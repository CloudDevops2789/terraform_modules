############################################
# Logically Air-Gapped Backup Vault
############################################

# Name of the logically air-gapped backup vault.
#
variable "name" {

  description = "Name of the logically air-gapped backup vault."

  type = string

}

############################################
# Retention Policy
############################################

# Minimum number of days that recovery
# points must be retained.
#
variable "min_retention_days" {

  description = "Minimum retention period."

  type = number

}

# Maximum number of days that recovery
# points can be retained.
#
variable "max_retention_days" {

  description = "Maximum retention period."

  type = number

}

############################################
# Encryption
############################################

# Optional KMS key used to encrypt the vault.
#
variable "encryption_key_arn" {

  description = "KMS Key ARN used for encryption."

  type = string

  default = null

}

############################################
# Resource Tags
############################################

variable "tags" {

  description = "Tags applied to the vault."

  type = map(string)

  default = {}

}