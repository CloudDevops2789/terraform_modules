# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to certificate generation.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Authentication type used by the Client VPN module test.
# Supported values mirror the reusable module.
variable "authentication_type" {
  description = "Authentication method used by the Client VPN module test."
  type        = string
  default     = "certificate"

  validation {
    condition = contains([
      "certificate",
      "federated",
      "directory",
      "directory_and_mutual",
    ], var.authentication_type)

    error_message = "authentication_type must be certificate, federated, directory, or directory_and_mutual."
  }
}

variable "active_directory_id" {
  description = "Existing AWS Directory Service directory ID used for directory authentication tests."
  type        = string
  default     = null
  nullable    = true
}

variable "saml_provider_arn" {
  description = "Existing IAM SAML provider ARN used when authentication_type is federated."
  type        = string
  default     = null
  nullable    = true
}

variable "server_certificate_arn" {
  description = "Existing ACM server certificate ARN supplied by the operator at runtime. Terraform never creates it."
  type        = string

  validation {
    condition     = length(trimspace(var.server_certificate_arn)) > 0
    error_message = "server_certificate_arn must be supplied at runtime."
  }
}

variable "root_certificate_chain_arn" {
  description = "Existing ACM client root CA certificate-chain ARN supplied at runtime for mutual-authentication modes. Terraform never creates it."
  type        = string
  default     = null
  nullable    = true
}

variable "access_group_id" {
  description = "Optional Active Directory group SID used to validate group-scoped authorization."
  type        = string
  default     = null
  nullable    = true
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
  description = "Additional organization-approved tags that do not redefine mandatory organization tags."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = length(setintersection(
      toset(keys(var.org_additional_tags)),
      toset([
        "org_it_cost_center",
        "org_department",
        "org_cmdb_calculated_app",
        "org_business_criticality",
        "org_environment",
        "org_data_classification",
        "org_project_name",
        "org_managed_by",
      ])
    )) == 0
    error_message = "org_additional_tags must not redefine mandatory organization tag keys."
  }

  validation {
    condition     = alltrue([for key in keys(var.org_additional_tags) : startswith(key, "org_")])
    error_message = "Every org_additional_tags key must start with org_."
  }
}
