############################################
# Backup Selection Configuration
############################################

# Name of the Backup Selection.
#
variable "name" {

  description = "Name of the Backup Selection."

  type = string

}

# ID of the AWS Backup Plan that this
# selection will associate resources with.
#
variable "backup_plan_id" {

  description = "AWS Backup Plan ID."

  type = string

}

# ARN of the IAM Role assumed by
# AWS Backup.
#
variable "iam_role_arn" {

  description = "IAM Role ARN used by AWS Backup."

  type = string

}

# List of AWS resource ARNs that
# should be protected by this
# Backup Plan.
#
variable "resources" {

  description = "List of resource ARNs to protect."

  type = list(string)

}

############################################
# Resource Tags
############################################

variable "tags" {

  description = "Tags applied to supported resources."

  type = map(string)

  default = {}

}