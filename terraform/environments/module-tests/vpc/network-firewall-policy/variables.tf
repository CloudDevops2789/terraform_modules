##################################################################################################
# AWS Region
##################################################################################################
variable "aws_region" {
  description = "AWS Region used to validate the Network Firewall policy module."
  type        = string
  default     = "us-east-1"
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
