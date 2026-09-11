# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to key pair generation below.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the Recovery stack variable for direct contract tracing.
#
# Required, not optional - unlike client-vpn's certificates, there is no
# safe way to auto-generate a real SSH key pair's public half as a static
# default (a hardcoded public key committed to this repository would be a
# key everyone could use), so an operator must always supply the path to
# their own public key. This does not override a generated resource - it
# is the only source for the key-pair module's input in compute.tf, which
# in turn lets this test exercise the ec2 module's `key_name` attribute
# instead of leaving it at its default (unset).
variable "public_key_path" {
  description = "Path to the SSH public key used to create the supporting key pair."
  type        = string
}

variable "org_it_cost_center" {
  description = "Organization-approved IT cost center associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_it_cost_center)) > 0
    error_message = "org_it_cost_center must not be empty."
  }
}

variable "org_department" {
  description = "Organization-approved department associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_department)) > 0
    error_message = "org_department must not be empty."
  }
}

variable "org_cmdb_calculated_app" {
  description = "Organization-approved CMDB calculated application associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_cmdb_calculated_app)) > 0
    error_message = "org_cmdb_calculated_app must not be empty."
  }
}

variable "org_business_criticality" {
  description = "Organization-approved business criticality associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_business_criticality)) > 0
    error_message = "org_business_criticality must not be empty."
  }
}

variable "org_environment" {
  description = "Organization-approved environment classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_environment)) > 0
    error_message = "org_environment must not be empty."
  }
}

variable "org_data_classification" {
  description = "Organization-approved data classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_data_classification)) > 0
    error_message = "org_data_classification must not be empty."
  }
}

variable "org_project_name" {
  description = "Organization-approved project name associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_project_name)) > 0
    error_message = "org_project_name must not be empty."
  }
}

variable "org_managed_by" {
  description = "Organization-approved identifier for the system or team managing the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_managed_by)) > 0
    error_message = "org_managed_by must not be empty."
  }
}

variable "org_additional_tags" {
  description = "Optional additional AWS resource tags. Keys do not require the standard organization prefix and may override standard test-harness tags."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.org_additional_tags) :
      length(key) > 0 &&
      length(key) <= 128 &&
      !startswith(lower(key), "aws:")
    ])

    error_message = "Additional tag keys must be 1-128 characters and must not use the reserved aws: prefix."
  }

  validation {
    condition = alltrue([
      for value in values(var.org_additional_tags) :
      length(value) <= 256
    ])

    error_message = "Additional tag values must not exceed 256 characters."
  }
}
