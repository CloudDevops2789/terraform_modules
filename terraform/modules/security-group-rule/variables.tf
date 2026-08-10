# type must be "ingress" or "egress" - it is what the locals block in
# security-group-rule.tf filters on.
#
# ip_protocol accepts a protocol name ("tcp", "udp", "icmp") or "-1",
# which means all protocols. When ip_protocol is "-1" the port range is
# omitted entirely, which is why from_port and to_port are optional.
#
# The four source attributes are mutually exclusive: set exactly one of
# cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id.
# Referencing another security group is preferred over a CIDR when both
# ends are inside AWS, since it survives IP changes.
variable "rules" {
  description = "Security group rules to create."

  type = map(object({
    type              = string
    security_group_id = string
    description       = optional(string)

    ip_protocol = string
    from_port   = optional(number)
    to_port     = optional(number)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      contains(["ingress", "egress"], rule.type)
    ])

    error_message = "Each security group rule type must be either 'ingress' or 'egress'."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      length(trimspace(rule.security_group_id)) > 0 &&
      length(trimspace(rule.ip_protocol)) > 0
    ])

    error_message = "security_group_id and ip_protocol must not be empty."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      length([
        for source in [
          rule.cidr_ipv4,
          rule.cidr_ipv6,
          rule.prefix_list_id,
          rule.referenced_security_group_id,
        ] : source
        if source != null
      ]) == 1
    ])

    error_message = "Each security group rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }

  validation {
    condition = alltrue(flatten([
      for rule in values(var.rules) : [
        rule.cidr_ipv4 == null ? true : length(trimspace(rule.cidr_ipv4)) > 0,
        rule.cidr_ipv6 == null ? true : length(trimspace(rule.cidr_ipv6)) > 0,
        rule.prefix_list_id == null ? true : length(trimspace(rule.prefix_list_id)) > 0,
        rule.referenced_security_group_id == null ? true : length(trimspace(rule.referenced_security_group_id)) > 0,
      ]
    ]))

    error_message = "Configured security group rule source values must not be empty strings."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      (
        rule.cidr_ipv4 == null ? true : (
          can(cidrhost(rule.cidr_ipv4, 0)) &&
          !strcontains(rule.cidr_ipv4, ":")
        )
      ) &&
      (
        rule.cidr_ipv6 == null ? true : (
          can(cidrhost(rule.cidr_ipv6, 0)) &&
          strcontains(rule.cidr_ipv6, ":")
        )
      )
    ])

    error_message = "cidr_ipv4 must contain a valid IPv4 CIDR and cidr_ipv6 must contain a valid IPv6 CIDR."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      (
        rule.from_port == null && rule.to_port == null
        ) || (
        rule.from_port != null && rule.to_port != null
      )
    ])

    error_message = "from_port and to_port must either both be supplied or both be omitted."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      rule.ip_protocol != "-1" ? true : (
        rule.from_port == null &&
        rule.to_port == null
      )
    ])

    error_message = "Rules using ip_protocol '-1' must not define from_port or to_port."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      contains(
        ["tcp", "udp", "6", "17"],
        lower(trimspace(rule.ip_protocol))
        ) ? (
        rule.from_port != null &&
        rule.to_port != null &&
        try(
          rule.from_port >= 0 &&
          rule.from_port <= 65535 &&
          rule.to_port >= 0 &&
          rule.to_port <= 65535 &&
          rule.from_port == floor(rule.from_port) &&
          rule.to_port == floor(rule.to_port) &&
          rule.from_port <= rule.to_port,
          false
        )
      ) : true
    ])

    error_message = "TCP and UDP rules must define whole-number from_port and to_port values from 0 to 65535, with from_port less than or equal to to_port."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      contains(
        ["icmp", "1"],
        lower(trimspace(rule.ip_protocol))
        ) ? (
        rule.from_port != null &&
        rule.to_port != null &&
        try(
          rule.from_port >= -1 &&
          rule.from_port <= 255 &&
          rule.to_port >= -1 &&
          rule.to_port <= 255 &&
          rule.from_port == floor(rule.from_port) &&
          rule.to_port == floor(rule.to_port) &&
          (
            rule.from_port != -1 ||
            rule.to_port == -1
          ),
          false
        )
      ) : true
    ])

    error_message = "ICMP rules must define whole-number type and code values from -1 to 255; when the ICMP type is -1, the code must also be -1."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      contains(
        ["icmpv6", "58"],
        lower(trimspace(rule.ip_protocol))
        ) ? (
        (
          rule.from_port == null &&
          rule.to_port == null
          ) || try(
          rule.from_port != null &&
          rule.to_port != null &&
          rule.from_port >= -1 &&
          rule.from_port <= 255 &&
          rule.to_port >= -1 &&
          rule.to_port <= 255 &&
          rule.from_port == floor(rule.from_port) &&
          rule.to_port == floor(rule.to_port) &&
          (
            rule.from_port != -1 ||
            rule.to_port == -1
          ),
          false
        )
      ) : true
    ])

    error_message = "ICMPv6 rules may omit type and code, or define whole-number values from -1 to 255; when the type is -1, the code must also be -1."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      rule.description == null ? true : (
        length(trimspace(rule.description)) > 0 &&
        length(rule.description) <= 255
      )
    ])

    error_message = "Rule descriptions must be non-empty when supplied and must not exceed 255 characters."
  }
}
