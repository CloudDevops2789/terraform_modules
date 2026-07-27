############################################
# IAM Role Configuration
############################################

# Name of the IAM Role used by AWS Backup.
#
variable "name" {

  description = "Name of the IAM Role."

  type = string

}

############################################
# Resource Tags
############################################

variable "tags" {

  description = "Tags applied to the IAM Role."

  type = map(string)

  default = {}

}