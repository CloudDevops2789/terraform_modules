# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to generated resources; it has
# nothing to do with certificates or passwords.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here. The
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
  description = "Organization IT cost center."
  type        = string
}

variable "org_department" {
  description = "Organization department."
  type        = string
}

variable "org_cmdb_calculated_app" {
  description = "CMDB calculated application identifier."
  type        = string
}

variable "org_business_criticality" {
  description = "Business criticality classification."
  type        = string

  validation {
    condition     = contains(["1", "2", "3", "4"], var.org_business_criticality)
    error_message = "org_business_criticality must be 1, 2, 3, or 4."
  }
}

variable "org_environment" {
  description = "Enterprise environment classification."
  type        = string

  validation {
    condition = contains(
      ["sandbox", "dev", "test", "qa", "stage", "prod"],
      lower(var.org_environment)
    )
    error_message = "org_environment must be sandbox, dev, test, qa, stage, or prod."
  }
}

variable "org_data_classification" {
  description = "Enterprise data classification."
  type        = string

  validation {
    condition = contains(
      ["public", "internal", "confidential", "restricted"],
      lower(var.org_data_classification)
    )
    error_message = "org_data_classification must be public, internal, confidential, or restricted."
  }
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags applied to resources in this test root."
  type        = map(string)
  default     = {}
}
