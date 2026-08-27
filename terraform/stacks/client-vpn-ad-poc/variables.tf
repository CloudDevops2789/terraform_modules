variable "aws_region" {
  description = "AWS Region selected by the AAP AssumeRole binding."
  type        = string
}

variable "domain_name" {
  description = "DNS name of the short-lived AWS Managed Microsoft AD test directory."
  type        = string

  validation {
    condition = (
      length(trimspace(var.domain_name)) > 0 &&
      strcontains(var.domain_name, ".") &&
      length(regexall("\\s", var.domain_name)) == 0
    )
    error_message = "domain_name must be a non-empty DNS FQDN."
  }
}

variable "directory_edition" {
  description = "AWS Managed Microsoft AD edition used by the proof environment."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Enterprise"], var.directory_edition)
    error_message = "directory_edition must be Standard or Enterprise."
  }
}

variable "managed_ad_password" {
  description = "Bootstrap password supplied only by the approved AAP Managed AD credential."
  type        = string
  sensitive   = true
}

variable "client_vpn_enabled" {
  description = "Create the Client VPN resources after the directory user and access group have been bootstrapped."
  type        = bool
  default     = false
  nullable    = false
}

variable "authentication_type" {
  description = "POC authentication mode: directory or directory_and_mutual."
  type        = string
  default     = "directory"

  validation {
    condition     = contains(["directory", "directory_and_mutual"], var.authentication_type)
    error_message = "authentication_type must be directory or directory_and_mutual for this POC."
  }
}

variable "client_vpn_access_group_id" {
  description = "Optional Active Directory group SID returned by the directory bootstrap job."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.client_vpn_access_group_id == null ? true : (
      length(trimspace(var.client_vpn_access_group_id)) > 0
    )
    error_message = "client_vpn_access_group_id must be null or a non-empty SID."
  }
}

variable "server_certificate_arn" {
  description = "Existing ACM server certificate ARN. Required when the Client VPN stage is enabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      try(length(trimspace(var.server_certificate_arn)) > 0, false)
    )
    error_message = "server_certificate_arn must be supplied at runtime when client_vpn_enabled is true."
  }
}

variable "root_certificate_chain_arn" {
  description = "Existing ACM client root CA ARN. Required for directory_and_mutual mode."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      var.authentication_type != "directory_and_mutual" ||
      try(length(trimspace(var.root_certificate_chain_arn)) > 0, false)
    )
    error_message = "root_certificate_chain_arn must be supplied at runtime for directory_and_mutual authentication."
  }
}

variable "public_key" {
  description = "Operator-owned SSH public key material registered as the EC2 key pair; the private key never enters Terraform."
  type        = string

  validation {
    condition     = length(trimspace(var.public_key)) > 0
    error_message = "public_key must not be empty."
  }
}

variable "vpc_cidr_block" {
  description = "CIDR allocated to the isolated POC VPC."
  type        = string
  default     = "10.250.0.0/16"
}

variable "client_cidr_block" {
  description = "Non-overlapping address pool assigned to Client VPN users."
  type        = string
  default     = "172.27.240.0/22"
}

variable "test_instance_type" {
  description = "Windows EC2 instance type used as the private connectivity target."
  type        = string
  default     = "t3.micro"
}

variable "organization_tag_key_prefix" {
  description = "Prefix applied to mandatory organization tag keys."
  type        = string
  default     = "org_"
}

variable "org_it_cost_center" {
  type = string
}

variable "org_department" {
  type = string
}

variable "org_cmdb_calculated_app" {
  type = string
}

variable "org_business_criticality" {
  type = string
}

variable "org_environment" {
  type = string
}

variable "org_data_classification" {
  type = string
}

variable "org_project_name" {
  type = string
}

variable "org_managed_by" {
  type = string
}

variable "org_additional_tags" {
  type     = map(string)
  default  = {}
  nullable = false
}
