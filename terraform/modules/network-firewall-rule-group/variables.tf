##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Creates one or more stateful Network Firewall rule groups.
#
# The schema intentionally mirrors the AWS Network Firewall resource so
# enterprise configurations require minimal translation.
variable "stateful_rule_groups" {
  description = "Stateful Network Firewall rule groups."
  type = map(object({
    description = optional(string)
    capacity    = number
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    stateful_rule_options = optional(object({
      rule_order = optional(string, "DEFAULT_ACTION_ORDER")
    }))
    rule_variables = optional(object({
      ip_sets = optional(map(object({
        definition = list(string)
      })), {})
      port_sets = optional(map(object({
        definition = list(string)
      })), {})
    }))
    reference_sets = optional(object({
      ip_set_references = optional(map(object({
        reference_arn = string
      })), {})
    }))
    rules_source = object({
      rules_string = optional(string)
      rules_source_list = optional(object({
        generated_rules_type = string
        target_types         = set(string)
        targets              = set(string)
      }))
      stateful_rules = optional(list(object({
        action = string
        header = object({
          destination      = string
          destination_port = string
          direction        = string
          protocol         = string
          source           = string
          source_port      = string
        })
        rule_options = list(object({
          keyword  = string
          settings = optional(list(string), [])
        }))
      })), [])
    })
  }))
  default = {}
}

##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Creates one or more stateless Network Firewall rule groups.
variable "stateless_rule_groups" {
  description = "Stateless Network Firewall rule groups."
  type = map(object({
    description = optional(string)
    capacity    = number
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    rules_source = object({
      stateless_rules = list(object({
        priority = number
        rule_definition = object({
          actions = list(string)
          match_attributes = object({
            sources = optional(list(object({
              address_definition = string
            })), [])
            destinations = optional(list(object({
              address_definition = string
            })), [])
            source_ports = optional(list(object({
              from_port = number
              to_port   = number
            })), [])
            destination_ports = optional(list(object({
              from_port = number
              to_port   = number
            })), [])
            protocols = optional(list(number), [])
            tcp_flags = optional(list(object({
              flags = list(string)
              masks = list(string)
            })), [])
          })
        })
      }))
      custom_actions = optional(list(object({
        action_name = string
        dimensions = list(object({
          value = string
        }))
      })), [])
    })
  }))
  default = {}
}

##################################################################################################
# Tags
##################################################################################################
# Tags applied to every rule group created by this module.
variable "tags" {
  description = "Tags applied to all rule groups."
  type        = map(string)
  default     = {}
}