##################################################################################################
# Test Inputs
##################################################################################################
variable "aws_region" {
  description = "AWS Region used to validate the Network Firewall routing module."
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  description = "IPv4 CIDR block for the isolated module-test VPC."
  type        = string
  default     = "10.254.0.0/16"
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
