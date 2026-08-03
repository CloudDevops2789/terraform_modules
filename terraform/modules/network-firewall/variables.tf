##################################################################################################
# Common Tags
##################################################################################################
variable "tags" {
  description = "Tags applied to every Network Firewall and VPC endpoint association created by this module."
  type        = map(string)
  default     = {}
}
##################################################################################################
# Network Firewalls
##################################################################################################
# Each map entry creates either a VPC-attached firewall or a Transit Gateway-attached firewall.
# The logical map key provides a stable Terraform address. The AWS firewall name remains explicit
# so the consuming environment controls enterprise naming independently from Terraform addressing.
variable "firewalls" {
  description = "AWS Network Firewalls keyed by stable logical identifiers."
  type = map(object({
    name                                = string
    description                         = optional(string)
    firewall_policy_arn                 = string
    vpc_id                              = optional(string)
    transit_gateway_id                  = optional(string)
    availability_zone_change_protection = optional(bool, false)
    delete_protection                   = optional(bool, false)
    firewall_policy_change_protection   = optional(bool, false)
    subnet_change_protection            = optional(bool, false)
    enabled_analysis_types              = optional(set(string), [])
    availability_zone_mappings = optional(map(object({
      availability_zone_id = string
    })), {})
    subnet_mappings = optional(map(object({
      subnet_id       = string
      ip_address_type = optional(string, "IPV4")
    })), {})
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    timeouts = optional(object({
      create = optional(string, "60m")
      update = optional(string, "60m")
      delete = optional(string, "60m")
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      length(firewall.name) >= 1 &&
      length(firewall.name) <= 128 &&
      can(regex("^[A-Za-z0-9-]+$", firewall.name))
    ])
    error_message = "Every firewall name must contain 1-128 alphanumeric or hyphen characters."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.description == null || length(firewall.description) <= 512
    ])
    error_message = "Firewall descriptions must contain no more than 512 characters."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      can(regex("^arn:[^:]+:network-firewall:[^:]+:[0-9]{12}:firewall-policy/.+$", firewall.firewall_policy_arn))
    ])
    error_message = "Every firewall_policy_arn must be a valid AWS Network Firewall policy ARN."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      (firewall.vpc_id != null ? 1 : 0) +
      (firewall.transit_gateway_id != null ? 1 : 0) == 1
    ])
    error_message = "Every firewall must define exactly one attachment target: vpc_id or transit_gateway_id."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.vpc_id == null || can(regex("^vpc-[0-9a-f]+$", firewall.vpc_id))
    ])
    error_message = "vpc_id must use the AWS VPC identifier format."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.transit_gateway_id == null || can(regex("^tgw-[0-9a-z]+$", firewall.transit_gateway_id))
    ])
    error_message = "transit_gateway_id must use the AWS Transit Gateway identifier format."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.vpc_id == null ? (
        length(firewall.subnet_mappings) == 0 &&
        length(firewall.availability_zone_mappings) >= 1
        ) : (
        length(firewall.subnet_mappings) >= 1 &&
        length(firewall.availability_zone_mappings) == 0
      )
    ])
    error_message = "VPC-attached firewalls require subnet_mappings only; Transit Gateway-attached firewalls require availability_zone_mappings only."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      length([
        for mapping in values(firewall.subnet_mappings) :
        mapping.subnet_id
        ]) == length(distinct([
          for mapping in values(firewall.subnet_mappings) :
          mapping.subnet_id
      ]))
    ])
    error_message = "Subnet IDs must be unique within each firewall."
  }
  validation {
    condition = alltrue(flatten([
      for firewall in values(var.firewalls) : [
        for mapping in values(firewall.subnet_mappings) :
        can(regex("^subnet-[0-9a-f]+$", mapping.subnet_id))
      ]
    ]))
    error_message = "Every subnet mapping must contain a valid AWS subnet ID."
  }
  validation {
    condition = alltrue(flatten([
      for firewall in values(var.firewalls) : [
        for mapping in values(firewall.subnet_mappings) :
        contains(["IPV4", "DUALSTACK"], mapping.ip_address_type)
      ]
    ]))
    error_message = "Firewall subnet ip_address_type must be IPV4 or DUALSTACK."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      length(setsubtract(
        firewall.enabled_analysis_types,
        toset(["TLS_SNI", "HTTP_HOST"])
      )) == 0
    ])
    error_message = "enabled_analysis_types supports only TLS_SNI and HTTP_HOST."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.encryption_configuration == null ||
      contains(["AWS_OWNED_KMS_KEY", "CUSTOMER_KMS"], firewall.encryption_configuration.type)
    ])
    error_message = "Encryption type must be AWS_OWNED_KMS_KEY or CUSTOMER_KMS."
  }
  validation {
    condition = alltrue([
      for firewall in values(var.firewalls) :
      firewall.encryption_configuration == null ||
      firewall.encryption_configuration.type != "CUSTOMER_KMS" ||
      try(firewall.encryption_configuration.key_id, null) != null
    ])
    error_message = "CUSTOMER_KMS encryption requires key_id."
  }
}
##################################################################################################
# VPC Endpoint Associations
##################################################################################################
# Associations create additional firewall endpoints after a VPC-attached firewall exists. They can
# target a firewall created by this module through firewall_key, or an external/shared firewall ARN.
variable "vpc_endpoint_associations" {
  description = "Optional additional Network Firewall VPC endpoint associations keyed by stable logical identifiers."
  type = map(object({
    firewall_key = optional(string)
    firewall_arn = optional(string)
    vpc_id       = string
    description  = optional(string)
    subnet_mapping = object({
      subnet_id       = string
      ip_address_type = optional(string, "IPV4")
    })
    timeouts = optional(object({
      create = optional(string, "30m")
      delete = optional(string, "30m")
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      (association.firewall_key != null ? 1 : 0) +
      (association.firewall_arn != null ? 1 : 0) == 1
    ])
    error_message = "Every VPC endpoint association must define exactly one of firewall_key or firewall_arn."
  }
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      association.firewall_arn == null ||
      can(regex("^arn:[^:]+:network-firewall:[^:]+:[0-9]{12}:firewall/.+$", association.firewall_arn))
    ])
    error_message = "firewall_arn must be a valid AWS Network Firewall ARN."
  }
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      can(regex("^vpc-[0-9a-f]+$", association.vpc_id))
    ])
    error_message = "Every VPC endpoint association vpc_id must use the AWS VPC identifier format."
  }
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      can(regex("^subnet-[0-9a-f]+$", association.subnet_mapping.subnet_id))
    ])
    error_message = "Every VPC endpoint association subnet_id must use the AWS subnet identifier format."
  }
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      contains(["IPV4", "DUALSTACK"], association.subnet_mapping.ip_address_type)
    ])
    error_message = "VPC endpoint association ip_address_type must be IPV4 or DUALSTACK."
  }
  validation {
    condition = alltrue([
      for association in values(var.vpc_endpoint_associations) :
      association.description == null || length(association.description) <= 512
    ])
    error_message = "VPC endpoint association descriptions must contain no more than 512 characters."
  }
}
