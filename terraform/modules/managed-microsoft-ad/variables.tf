############################################################
# AWS Managed Microsoft AD Variables
############################################################

variable "domain_name" {
  description = "Fully qualified domain name (FQDN) for the AWS Managed Microsoft AD directory."
  type        = string
}

variable "password" {
  description = "Initial Admin password. Terraform state retains this sensitive value; rotate it operationally after directory creation."
  type        = string
  sensitive   = true

  validation {
    condition = nonsensitive(
      length(var.password) >= 8 &&
      length(var.password) <= 64 &&
      !strcontains(lower(var.password), "admin") &&
      sum([
        length(regexall("[A-Z]", var.password)) > 0 ? 1 : 0,
        length(regexall("[a-z]", var.password)) > 0 ? 1 : 0,
        length(regexall("[0-9]", var.password)) > 0 ? 1 : 0,
        length(regexall("[^A-Za-z0-9]", var.password)) > 0 ? 1 : 0
      ]) >= 3
    )
    error_message = "Password must be 8-64 characters, must not contain admin, and must include at least three of: uppercase, lowercase, number, or special character."
  }
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

variable "enable_directory_data_access" {
  description = "Enable AWS Directory Service Data API access for caller-owned user and group automation."
  type        = bool
  default     = false
  nullable    = false
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

variable "client_cidr_blocks" {
  description = "Approved external client CIDRs that require native Active Directory access. Exclude the directory VPC CIDR because AWS owns its baseline rules."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.client_cidr_blocks :
      can(cidrnetmask(cidr))
    ])
    error_message = "Every client_cidr_blocks entry must be a valid IPv4 CIDR."
  }
}

variable "tags" {
  description = "Map of tags to apply to the directory."

  type    = map(string)
  default = {}
}
