variable "rules" {
  description = "Security group rules to create."

  type = map(object({
    type              = string
    security_group_id = string

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