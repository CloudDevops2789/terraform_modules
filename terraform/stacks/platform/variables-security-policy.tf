##################################################################################################
# Security Policy Variables
##################################################################################################

variable "security_group_rules" {
  description = <<-EOT
    Configuration-driven security group policy for Platform resources.

    Rules use logical security-group and network-zone names rather than
    hard-coded AWS security group IDs or VPC CIDRs.

    security_group and security_group peers reference keys from the
    security_groups map. VPC peers reference keys from network_config.vpcs.
    This allows new workload roles and service security groups to be added
    through environment configuration without changing reusable Platform code.

    Supported peer types:
      - security_group
      - vpc
      - cidr

    CIDR peers should be used only when a logical VPC or security-group
    reference cannot represent the required access path.
  EOT

  type = list(object({
    name           = string
    direction      = string
    security_group = string

    protocol  = string
    from_port = optional(number)
    to_port   = optional(number)

    peer_type = string
    peer      = string

    description = string
    enabled     = optional(bool, true)
  }))

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(
        keys(var.security_groups),
        rule.security_group
      )
    ])

    error_message = "Every security_group must reference an existing security_groups key."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(["ingress", "egress"], rule.direction)
    ])

    error_message = "direction must be ingress or egress."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(
        ["security_group", "vpc", "cidr"],
        rule.peer_type
      )
    ])

    error_message = "peer_type must be security_group, vpc, or cidr."
  }

  validation {
    condition = (
      length(distinct([
        for rule in var.security_group_rules : rule.name
      ])) == length(var.security_group_rules)
    )

    error_message = "Every security group rule name must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      rule.peer_type != "security_group" ||
      contains(
        keys(var.security_groups),
        rule.peer
      )
    ])

    error_message = "Every security_group peer must reference an existing security_groups key."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      rule.peer_type != "vpc" ||
      contains(
        keys(var.network_config.vpcs),
        rule.peer
      )
    ])

    error_message = "Every VPC peer must reference an existing network_config.vpcs key."
  }
}

################################################################################
# Network Firewall Policy Rules
################################################################################

variable "network_firewall_rules" {
  description = <<-EOT
    Ordered AWS Network Firewall stateful rules.

    Rules are evaluated in the order supplied because the firewall policy
    uses STRICT_ORDER.

    source_zone and destination_zone use logical environment names rather
    than hard-coded CIDRs so the rules remain portable when network_config
    changes.

    Supported zones:
      - recovery_access
      - core_recovery
      - protected_data
      - any

    Supported actions:
      - pass
      - drop

    Supported protocols:
      - ip
      - tcp
      - udp
      - icmp
  EOT

  type = list(object({
    action           = string
    protocol         = string
    source_zone      = string
    source_port      = optional(string, "any")
    destination_zone = string
    destination_port = optional(string, "any")
    description      = string
    sid              = number
    enabled          = optional(bool, true)
  }))


  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["pass", "drop"], rule.action)
    ])

    error_message = "Each Network Firewall rule action must be either 'pass' or 'drop'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "tcp", "udp", "icmp"], rule.protocol)
    ])

    error_message = "Each Network Firewall rule protocol must be ip, tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.source_zone
      ) &&
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.destination_zone
      )
    ])

    error_message = "Firewall rule zones must be recovery_access, core_recovery, protected_data, or any."
  }

  validation {
    condition = (
      length(distinct([
        for rule in var.network_firewall_rules : rule.sid
      ])) == length(var.network_firewall_rules)
    )

    error_message = "Every Network Firewall rule SID must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      rule.sid > 0 && rule.sid == floor(rule.sid)
    ])

    error_message = "Every Network Firewall rule SID must be a positive whole number."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.network_firewall_rules : [
        for port in [rule.source_port, rule.destination_port] :
        port == "any" || (
          can(regex("^[0-9]{1,5}(:[0-9]{1,5})?$", port)) &&
          try(
            tonumber(split(":", port)[0]) >= 0 &&
            tonumber(split(":", port)[0]) <= 65535,
            false
          ) &&
          (
            length(split(":", port)) == 1
            ? true
            : try(
              tonumber(split(":", port)[1]) >= 0 &&
              tonumber(split(":", port)[1]) <= 65535 &&
              tonumber(split(":", port)[0]) <= tonumber(split(":", port)[1]),
              false
            )
          )
        )
      ]
    ]))

    error_message = "Firewall ports must be 'any', a port from 0 to 65535, or an ascending range such as '1024:65535'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "icmp"], rule.protocol)
      ? rule.source_port == "any" && rule.destination_port == "any"
      : true
    ])

    error_message = "Firewall rules using protocol 'ip' or 'icmp' must use 'any' for source_port and destination_port."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      length(trimspace(rule.description)) > 0 &&
      !strcontains(rule.description, "\"") &&
      !strcontains(rule.description, "\\") &&
      !strcontains(rule.description, ";") &&
      !strcontains(rule.description, "\n") &&
      !strcontains(rule.description, "\r")
    ])

    error_message = "Firewall rule descriptions must not be empty or contain double quotes, backslashes, semicolons, or newline characters."
  }
}
