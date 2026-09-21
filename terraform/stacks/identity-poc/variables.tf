################################################################################
# Identity PoC Variables
#
# This root exists only to validate Managed AD bootstrap automation against an
# existing VPC. It does not replace the normal Platform -> Identity lifecycle.
################################################################################

variable "aws_region" {
  description = "AWS Region for the PoC directory."
  type        = string
  nullable    = false
}

variable "domain_name" {
  description = "Fully qualified DNS name for the PoC Managed Microsoft AD."
  type        = string
}

variable "short_name" {
  description = "NetBIOS short name for the PoC directory."
  type        = string
}

variable "edition" {
  description = "Managed Microsoft AD edition."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Enterprise"], var.edition)
    error_message = "edition must be Standard or Enterprise."
  }
}

variable "vpc_id" {
  description = "Existing VPC ID used for the PoC directory."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID."
  }
}

variable "subnet_ids" {
  description = "Exactly two existing subnet IDs in different Availability Zones."
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) == 2 &&
      alltrue([
        for subnet_id in var.subnet_ids :
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "subnet_ids must contain exactly two valid AWS subnet IDs."
  }
}

variable "managed_ad_password" {
  description = "Initial Managed AD Admin password supplied only by the AAP credential."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Optional tags applied to the PoC directory."
  type        = map(string)
  default     = {}
}
