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
