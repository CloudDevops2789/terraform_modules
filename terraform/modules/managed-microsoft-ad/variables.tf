############################################################
# AWS Managed Microsoft AD Variables
############################################################

variable "domain_name" {
  description = "Fully qualified domain name (FQDN) for the AWS Managed Microsoft AD directory."
  type        = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "edition" {
  description = "Edition of AWS Managed Microsoft AD."

  type    = string
  default = "Standard" # Enterprise for larger deployments

  validation {
    condition     = contains(["Standard", "Enterprise"], var.edition)
    error_message = "Edition must be either Standard or Enterprise."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the directory will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Exactly two private subnet IDs in different Availability Zones."

  type = list(string)

  validation {
    condition     = length(var.subnet_ids) == 2
    error_message = "Exactly two subnet IDs must be provided."
  }
}

variable "tags" {
  description = "Map of tags to apply to the directory."

  type    = map(string)
  default = {}
}