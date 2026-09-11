# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to generated resources; it has
# nothing to do with certificates or passwords.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the Identity stack variable so maintainers can trace the
# validation input to its governed consumer contract. The
# directory password cannot be a static value in locals.tf - it is a secret,
# and secrets never belong in version control. It is declared here with no
# default, so Terraform refuses to apply without an operator supplying one
# via terraform.tfvars (untracked) or TF_VAR_managed_ad_password. It is
# required, not optional: AWS Managed Microsoft AD has no supporting
# resource that could generate a password on its behalf, so this
# environment cannot supply an automatic default the way client-vpn does
# for certificates.
variable "managed_ad_password" {
  description = "Password for the AWS Managed Microsoft AD directory administrator account."
  type        = string
  sensitive   = true
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
