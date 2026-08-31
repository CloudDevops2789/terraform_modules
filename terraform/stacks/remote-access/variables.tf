variable "aws_region" {
  description = "AWS Region selected by the AAP AssumeRole binding."
  type        = string
}

variable "remote_access_enabled" {
  description = "Whether the Remote Access stack creates AWS Client VPN resources."
  type        = bool
  default     = false
  nullable    = false
}

variable "name" {
  description = "Customer-neutral display name for the Client VPN endpoint."
  type        = string
  default     = "ire-remote-access"
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "platform_contract" {
  description = "Platform networking and security-group contract resolved by AAP."

  type = object({
    vpc_ids               = map(string)
    vpc_cidrs             = map(string)
    subnet_ids_by_group   = map(map(list(string)))
    subnet_cidrs_by_group = map(map(list(string)))
    security_group_ids    = map(string)
  })

  default  = null
  nullable = true
}

variable "identity_contract" {
  description = "Managed AD contract resolved by AAP from the Identity state."

  type = object({
    managed_ad_enabled = bool
    directory_id       = string
    directory_name     = string
    dns_ip_addresses   = list(string)
    security_group_id  = string
  })

  default  = null
  nullable = true

  validation {
    condition = !var.remote_access_enabled || try(
      var.identity_contract != null &&
      var.identity_contract.managed_ad_enabled &&
      length(trimspace(var.identity_contract.directory_id)) > 0,
      false
    )
    error_message = "Enabled Remote Access requires an enabled Managed AD identity contract with a directory ID."
  }
}

variable "network_binding" {
  description = "Logical Platform placement for Client VPN network associations."

  type = object({
    vpc_key               = string
    subnet_group          = string
    required_subnet_count = optional(number, 2)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      !var.remote_access_enabled ||
      try(
        var.network_binding != null &&
        var.network_binding.required_subnet_count > 0 &&
        floor(var.network_binding.required_subnet_count) == var.network_binding.required_subnet_count &&
        contains(keys(var.platform_contract.vpc_ids), var.network_binding.vpc_key) &&
        contains(
          keys(var.platform_contract.subnet_ids_by_group[var.network_binding.vpc_key]),
          var.network_binding.subnet_group
        ) &&
        length(
          var.platform_contract.subnet_ids_by_group[var.network_binding.vpc_key][var.network_binding.subnet_group]
        ) >= var.network_binding.required_subnet_count &&
        length(
          var.platform_contract.subnet_cidrs_by_group[var.network_binding.vpc_key][var.network_binding.subnet_group]
        ) >= var.network_binding.required_subnet_count,
        false
      )
    )
    error_message = "Enabled Remote Access requires a valid Platform VPC and enough matching association subnet IDs and CIDRs."
  }
}

variable "client_cidr_block" {
  description = "Non-overlapping address pool assigned to connected VPN clients."
  type        = string
  default     = "172.30.240.0/22"

  validation {
    condition     = can(cidrhost(var.client_cidr_block, 0))
    error_message = "client_cidr_block must be a valid IPv4 CIDR."
  }
}

variable "authentication_type" {
  description = "Authentication mode: directory initially or directory_and_mutual later."
  type        = string
  default     = "directory"

  validation {
    condition     = contains(["directory", "directory_and_mutual"], var.authentication_type)
    error_message = "authentication_type must be directory or directory_and_mutual."
  }
}

variable "server_certificate_arn" {
  description = "Existing ACM server certificate ARN supplied at AAP runtime."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.remote_access_enabled || try(
      can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", var.server_certificate_arn)) &&
      split(":", var.server_certificate_arn)[3] == var.aws_region,
      false
    )
    error_message = "Enabled Remote Access requires an ACM server certificate ARN in the deployment Region."
  }
}

variable "client_root_certificate_chain_arn" {
  description = "Existing ACM client root CA ARN supplied when mutual authentication is enabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.remote_access_enabled ||
      var.authentication_type != "directory_and_mutual" ||
      try(
        can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", var.client_root_certificate_chain_arn)) &&
        split(":", var.client_root_certificate_chain_arn)[3] == var.aws_region,
        false
      )
    )
    error_message = "directory_and_mutual mode requires an ACM client root certificate-chain ARN in the deployment Region."
  }
}

variable "client_vpn_access_group_id" {
  description = "Managed AD VPN authorization-group SID returned by the AAP user bootstrap workflow."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.remote_access_enabled || try(
      can(regex("^S-[0-9-]+$", var.client_vpn_access_group_id)),
      false
    )
    error_message = "Enabled Remote Access requires a Managed AD group SID."
  }
}

variable "dns_configuration" {
  description = "DNS configuration pushed to connected clients."

  type = object({
    mode               = optional(string, "vpc_resolver")
    custom_dns_servers = optional(list(string), [])
  })

  default  = {}
  nullable = false

  validation {
    condition     = contains(["vpc_resolver", "managed_ad", "custom"], var.dns_configuration.mode)
    error_message = "dns_configuration.mode must be vpc_resolver, managed_ad, or custom."
  }


  validation {
    condition = (
      var.dns_configuration.mode == "custom"
      ? (
        length(var.dns_configuration.custom_dns_servers) > 0 &&
        alltrue([
          for address in var.dns_configuration.custom_dns_servers :
          can(cidrhost("${address}/32", 0))
        ])
      )
      : length(var.dns_configuration.custom_dns_servers) == 0
    )
    error_message = "Custom DNS mode requires IPv4 addresses; other modes must leave custom_dns_servers empty."
  }

  validation {
    condition = (
      !var.remote_access_enabled ||
      var.dns_configuration.mode != "managed_ad" ||
      try(length(var.identity_contract.dns_ip_addresses) > 0, false)
    )
    error_message = "Managed AD DNS mode requires directory DNS addresses in the Identity contract."
  }
}

variable "authorization_vpc_keys" {
  description = "Platform VPC keys that the Managed AD group may access."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = !var.remote_access_enabled || try(
      length(var.authorization_vpc_keys) > 0 &&
      alltrue([
        for key in var.authorization_vpc_keys :
        contains(keys(var.platform_contract.vpc_ids), key)
      ]),
      false
    )
    error_message = "Enabled Remote Access requires at least one authorization VPC key present in the Platform contract."
  }
}

variable "endpoint_egress_rules" {
  description = "Explicit traffic allowed from Client VPN ENIs to approved Platform VPCs."

  type = map(object({
    destination_vpc_key = string
    protocol            = string
    from_port           = optional(number)
    to_port             = optional(number)
    description         = string
  }))

  default  = {}
  nullable = false

  validation {
    condition = !var.remote_access_enabled || try(alltrue([
      for rule in values(var.endpoint_egress_rules) :
      contains(keys(var.platform_contract.vpc_ids), rule.destination_vpc_key)
    ]), false)
    error_message = "Every endpoint egress destination must exist in the Platform contract."
  }
}

variable "target_ingress_rules" {
  description = "Approved Platform security groups and ports reachable from Client VPN association subnets."

  type = map(object({
    security_group_key = string
    protocol           = string
    from_port          = optional(number)
    to_port            = optional(number)
    description        = string
  }))

  default  = {}
  nullable = false

  validation {
    condition = !var.remote_access_enabled || try(alltrue([
      for rule in values(var.target_ingress_rules) :
      contains(keys(var.platform_contract.security_group_ids), rule.security_group_key)
    ]), false)
    error_message = "Every target ingress security-group key must exist in the Platform contract."
  }
}

variable "split_tunnel" {
  type     = bool
  default  = true
  nullable = false
}

variable "transport_protocol" {
  type    = string
  default = "udp"
}

variable "vpn_port" {
  type    = number
  default = 443
}

variable "session_timeout_hours" {
  type    = number
  default = 8
}

variable "enable_connection_logging" {
  type     = bool
  default  = true
  nullable = false
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}

variable "organization_tag_key_prefix" {
  type     = string
  default  = "org_"
  nullable = false
}

variable "org_it_cost_center" { type = string }
variable "org_department" { type = string }
variable "org_cmdb_calculated_app" { type = string }
variable "org_business_criticality" { type = string }
variable "org_environment" { type = string }
variable "org_data_classification" { type = string }
variable "org_project_name" { type = string }
variable "org_managed_by" { type = string }

variable "org_additional_tags" {
  type     = map(string)
  default  = {}
  nullable = false
}
