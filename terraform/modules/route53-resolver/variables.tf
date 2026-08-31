variable "name" {
  description = "Friendly name for the Route 53 Resolver endpoint."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "direction" {
  description = "Resolver endpoint direction. Forwarding rules require OUTBOUND."
  type        = string
  default     = "OUTBOUND"
  nullable    = false

  validation {
    condition     = contains(["INBOUND", "OUTBOUND"], var.direction)
    error_message = "direction must be INBOUND or OUTBOUND."
  }

  validation {
    condition     = var.direction == "OUTBOUND" || length(var.forwarding_rules) == 0
    error_message = "forwarding_rules can be configured only for an OUTBOUND endpoint."
  }
}

variable "resolver_endpoint_type" {
  description = "IP address family used by the Resolver endpoint."
  type        = string
  default     = "IPV4"
  nullable    = false

  validation {
    condition     = contains(["IPV4", "IPV6", "DUALSTACK"], var.resolver_endpoint_type)
    error_message = "resolver_endpoint_type must be IPV4, IPV6, or DUALSTACK."
  }
}

variable "protocols" {
  description = "DNS transport protocols enabled on the Resolver endpoint."
  type        = set(string)
  default     = ["Do53"]
  nullable    = false

  validation {
    condition = (
      length(var.protocols) > 0 &&
      alltrue([
        for protocol in var.protocols :
        contains(["Do53", "DoH", "DoH-FIPS"], protocol)
      ])
    )
    error_message = "protocols must contain one or more of Do53, DoH, or DoH-FIPS."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs in which Resolver endpoint ENIs are created."
  type        = list(string)
  nullable    = false

  validation {
    condition = (
      length(var.subnet_ids) >= 2 &&
      length(distinct(var.subnet_ids)) == length(var.subnet_ids) &&
      alltrue([for subnet_id in var.subnet_ids : length(trimspace(subnet_id)) > 0])
    )
    error_message = "subnet_ids must contain at least two distinct, non-empty subnet IDs."
  }
}

variable "security_group_ids" {
  description = "Security group IDs attached to the Resolver endpoint ENIs."
  type        = set(string)
  nullable    = false

  validation {
    condition = (
      length(var.security_group_ids) > 0 &&
      alltrue([for security_group_id in var.security_group_ids : length(trimspace(security_group_id)) > 0])
    )
    error_message = "security_group_ids must contain at least one non-empty security group ID."
  }
}

variable "forwarding_rules" {
  description = "Private DNS suffixes forwarded through an outbound endpoint."

  type = map(object({
    name        = optional(string)
    domain_name = string

    target_ips = list(object({
      ip   = string
      port = optional(number, 53)
    }))

    vpc_ids = optional(map(string), {})
    tags    = optional(map(string), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for rule_key, rule in var.forwarding_rules :
      length(trimspace(rule_key)) > 0 &&
      (rule.name == null ? true : length(trimspace(rule.name)) > 0) &&
      length(trimspace(rule.domain_name)) > 0 &&
      strcontains(rule.domain_name, ".") &&
      length(rule.target_ips) > 0 &&
      length(distinct([for target in rule.target_ips : "${target.ip}:${target.port}"])) == length(rule.target_ips) &&
      alltrue([
        for target in rule.target_ips :
        can(cidrhost("${target.ip}/32", 0)) &&
        target.port >= 1 && target.port <= 65535 && target.port == floor(target.port)
      ]) &&
      alltrue([
        for vpc_key, vpc_id in rule.vpc_ids :
        length(trimspace(vpc_key)) > 0 && length(trimspace(vpc_id)) > 0
      ])
    ])
    error_message = "Each forwarding rule requires a DNS suffix, unique valid IPv4 targets and ports, and non-empty VPC association keys and IDs."
  }
}

variable "query_log_config_id" {
  description = "Optional existing Route 53 Resolver query-log configuration ID."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.query_log_config_id == null ? true : length(trimspace(var.query_log_config_id)) > 0
    error_message = "query_log_config_id must be null or a non-empty string."
  }
}

variable "query_log_vpc_ids" {
  description = "VPC IDs associated with the existing Resolver query-log configuration."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = (
      length(var.query_log_vpc_ids) == 0 ||
      (
        var.query_log_config_id != null &&
        alltrue([
          for vpc_key, vpc_id in var.query_log_vpc_ids :
          length(trimspace(vpc_key)) > 0 && length(trimspace(vpc_id)) > 0
        ])
      )
    )
    error_message = "query_log_vpc_ids requires query_log_config_id and non-empty VPC keys and IDs."
  }
}

variable "tags" {
  description = "Tags supplied by the calling root module."
  type        = map(string)
  default     = {}
  nullable    = false
}
