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
}