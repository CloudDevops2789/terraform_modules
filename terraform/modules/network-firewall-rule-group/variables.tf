##################################################################################################
# Common Tags
##################################################################################################
# These tags are merged with rule-group-specific tags. The consuming environment remains responsible
# for defining organization-wide provider default_tags and mandatory enterprise tagging controls.
variable "tags" {
  description = "Tags applied to every Network Firewall rule group created by this module."
  type        = map(string)
  default     = {}
}
##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Each map entry creates one stateful or stateful-domain rule group. The logical map key provides a
# stable Terraform resource address, while name remains explicit so enterprise naming standards are
# controlled by the consuming environment.
variable "stateful_rule_groups" {
  description = "Stateful and stateful-domain AWS Network Firewall rule groups keyed by stable logical identifiers."
  type = map(object({
    name        = string
    description = optional(string)
    capacity    = number
    type        = optional(string, "STATEFUL")
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    rules = optional(string)
    rule_group = optional(object({
      reference_sets = optional(object({
        ip_set_references = optional(map(object({
          reference_arn = string
        })), {})
      }))
      rule_variables = optional(object({
        ip_sets = optional(map(object({
          definition = set(string)
        })), {})
        port_sets = optional(map(object({
          definition = set(string)
        })), {})
      }))
      rules_source = object({
        rules_string = optional(string)
        rules_source_list = optional(object({
          generated_rules_type = string
          target_types         = set(string)
          targets              = set(string)
        }))
        stateful_rule = optional(list(object({
          action = string
          header = object({
            destination      = string
            destination_port = string
            direction        = string
            protocol         = string
            source           = string
            source_port      = string
          })
          rule_option = list(object({
            keyword  = string
            settings = optional(set(string), [])
          }))
        })), [])
      })
      stateful_rule_options = optional(object({
        rule_order = string
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      length(rule_group.name) >= 1 &&
      length(rule_group.name) <= 128 &&
      can(regex("^[A-Za-z0-9-]+$", rule_group.name))
    ])
    error_message = "Every stateful rule group name must contain 1-128 alphanumeric or hyphen characters."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.capacity >= 1 && rule_group.capacity <= 50000
    ])
    error_message = "Every stateful rule group capacity must be between 1 and 50000 capacity units."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      contains(["STATEFUL", "STATEFUL_DOMAIN"], rule_group.type)
    ])
    error_message = "Stateful rule group type must be STATEFUL or STATEFUL_DOMAIN."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      (rule_group.rules != null ? 1 : 0) + (rule_group.rule_group != null ? 1 : 0) == 1
    ])
    error_message = "Every stateful rule group must define exactly one of rules or rule_group."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.rule_group == null ? true : (
        (rule_group.rule_group.rules_source.rules_string != null ? 1 : 0) +
        (rule_group.rule_group.rules_source.rules_source_list != null ? 1 : 0) +
        (length(rule_group.rule_group.rules_source.stateful_rule) > 0 ? 1 : 0) == 1
      )
    ])
    error_message = "A structured stateful rule_group must define exactly one rules source: rules_string, rules_source_list, or one or more stateful_rule entries."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.rule_group == null ||
      rule_group.rule_group.stateful_rule_options == null ||
      contains(["DEFAULT_ACTION_ORDER", "STRICT_ORDER"], rule_group.rule_group.stateful_rule_options.rule_order)
    ])
    error_message = "stateful_rule_options.rule_order must be DEFAULT_ACTION_ORDER or STRICT_ORDER."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.rule_group == null ||
      rule_group.rule_group.stateful_rule_options == null ||
      rule_group.rule_group.stateful_rule_options.rule_order != "STRICT_ORDER" ||
      rule_group.rule_group.rules_source.rules_source_list == null
    ])
    error_message = "STRICT_ORDER cannot be used with rules_source_list domain-list rules."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateful_rule_groups) : [
        for rule in rule_group.rule_group == null ? [] : rule_group.rule_group.rules_source.stateful_rule :
        contains(["ALERT", "DROP", "PASS", "REJECT"], rule.action)
      ]
    ]))
    error_message = "Stateful rule actions must be ALERT, DROP, PASS, or REJECT."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateful_rule_groups) : [
        for rule in rule_group.rule_group == null ? [] : rule_group.rule_group.rules_source.stateful_rule :
        contains(["ANY", "FORWARD"], rule.header.direction)
      ]
    ]))
    error_message = "Stateful rule header direction must be ANY or FORWARD."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateful_rule_groups) : [
        for rule in rule_group.rule_group == null ? [] : rule_group.rule_group.rules_source.stateful_rule :
        contains(["IP", "TCP", "UDP", "ICMP", "HTTP", "FTP", "TLS", "SMB", "DNS", "DCERPC", "SSH", "SMTP", "IMAP", "MSN", "KRB5", "IKEV2", "TFTP", "NTP", "DHCP"], rule.header.protocol)
      ]
    ]))
    error_message = "A stateful rule header contains an unsupported protocol."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.encryption_configuration == null ||
      contains(["AWS_OWNED_KMS_KEY", "CUSTOMER_KMS"], rule_group.encryption_configuration.type)
    ])
    error_message = "Encryption type must be AWS_OWNED_KMS_KEY or CUSTOMER_KMS."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateful_rule_groups) :
      rule_group.encryption_configuration == null ||
      rule_group.encryption_configuration.type != "CUSTOMER_KMS" ||
      try(rule_group.encryption_configuration.key_id, null) != null
    ])
    error_message = "CUSTOMER_KMS encryption requires key_id."
  }
}
##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Each map entry creates one stateless rule group. Match attributes mirror the AWS provider's nested
# blocks so existing enterprise rule definitions can be adopted without weakening Terraform typing.
variable "stateless_rule_groups" {
  description = "Stateless AWS Network Firewall rule groups keyed by stable logical identifiers."
  type = map(object({
    name        = string
    description = optional(string)
    capacity    = number
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    rule_group = object({
      rules_source = object({
        stateless_rules_and_custom_actions = object({
          custom_action = optional(map(object({
            dimensions = set(string)
          })), {})
          stateless_rule = list(object({
            priority = number
            rule_definition = object({
              actions = set(string)
              match_attributes = object({
                destination = optional(list(object({
                  address_definition = string
                })), [])
                destination_port = optional(list(object({
                  from_port = number
                  to_port   = optional(number)
                })), [])
                protocols = optional(set(number), [])
                source = optional(list(object({
                  address_definition = string
                })), [])
                source_port = optional(list(object({
                  from_port = number
                  to_port   = optional(number)
                })), [])
                tcp_flag = optional(list(object({
                  flags = set(string)
                  masks = optional(set(string), [])
                })), [])
              })
            })
          }))
        })
      })
    })
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for rule_group in values(var.stateless_rule_groups) :
      length(rule_group.name) >= 1 &&
      length(rule_group.name) <= 128 &&
      can(regex("^[A-Za-z0-9-]+$", rule_group.name))
    ])
    error_message = "Every stateless rule group name must contain 1-128 alphanumeric or hyphen characters."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateless_rule_groups) :
      rule_group.capacity >= 1 && rule_group.capacity <= 30000
    ])
    error_message = "Every stateless rule group capacity must be between 1 and 30000 capacity units."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateless_rule_groups) :
      length(rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule) > 0
    ])
    error_message = "Every stateless rule group must contain at least one stateless_rule."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateless_rule_groups) : [
        for rule in rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule :
        rule.priority >= 1 && rule.priority <= 65535
      ]
    ]))
    error_message = "Stateless rule priorities must be between 1 and 65535."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateless_rule_groups) : [
        for rule in rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule :
        length(rule.rule_definition.actions) > 0
      ]
    ]))
    error_message = "Every stateless rule must define at least one action."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateless_rule_groups) : [
        for rule in rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule :
        alltrue([
          for port in concat(rule.rule_definition.match_attributes.source_port, rule.rule_definition.match_attributes.destination_port) :
          port.from_port >= 0 &&
          port.from_port <= 65535 &&
          coalesce(port.to_port, port.from_port) >= port.from_port &&
          coalesce(port.to_port, port.from_port) <= 65535
        ])
      ]
    ]))
    error_message = "Stateless source and destination ports must use valid 0-65535 ranges."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateless_rule_groups) : [
        for rule in rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule :
        alltrue([
          for protocol in rule.rule_definition.match_attributes.protocols :
          protocol >= 0 && protocol <= 255
        ])
      ]
    ]))
    error_message = "Stateless protocol numbers must be between 0 and 255."
  }
  validation {
    condition = alltrue(flatten([
      for rule_group in values(var.stateless_rule_groups) : [
        for rule in rule_group.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule :
        alltrue(flatten([
          for tcp_flag in rule.rule_definition.match_attributes.tcp_flag : [
            for flag in setunion(tcp_flag.flags, tcp_flag.masks) :
            contains(["FIN", "SYN", "RST", "PSH", "ACK", "URG", "ECE", "CWR"], flag)
          ]
        ]))
      ]
    ]))
    error_message = "TCP flags and masks must use FIN, SYN, RST, PSH, ACK, URG, ECE, or CWR."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateless_rule_groups) :
      rule_group.encryption_configuration == null ||
      contains(["AWS_OWNED_KMS_KEY", "CUSTOMER_KMS"], rule_group.encryption_configuration.type)
    ])
    error_message = "Encryption type must be AWS_OWNED_KMS_KEY or CUSTOMER_KMS."
  }
  validation {
    condition = alltrue([
      for rule_group in values(var.stateless_rule_groups) :
      rule_group.encryption_configuration == null ||
      rule_group.encryption_configuration.type != "CUSTOMER_KMS" ||
      try(rule_group.encryption_configuration.key_id, null) != null
    ])
    error_message = "CUSTOMER_KMS encryption requires key_id."
  }
}
