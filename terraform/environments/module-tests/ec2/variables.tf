# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to key pair generation below.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here.
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
