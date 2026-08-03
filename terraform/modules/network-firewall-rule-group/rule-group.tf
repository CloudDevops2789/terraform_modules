##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Stateful rule groups may consume either a top-level Suricata rules document or the structured
# rule_group API. The module intentionally exposes both provider-supported paths for enterprise
# migrations and centrally maintained rule libraries.
resource "aws_networkfirewall_rule_group" "stateful" {
  for_each    = local.stateful_rule_groups
  capacity    = each.value.capacity
  description = each.value.description
  name        = each.value.name
  rules       = each.value.rules
  type        = each.value.type
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      key_id = encryption_configuration.value.key_id
      type   = encryption_configuration.value.type
    }
  }
  dynamic "rule_group" {
    for_each = each.value.rule_group == null ? [] : [each.value.rule_group]
    content {
      dynamic "reference_sets" {
        for_each = rule_group.value.reference_sets == null ? [] : [rule_group.value.reference_sets]
        content {
          dynamic "ip_set_references" {
            for_each = reference_sets.value.ip_set_references
            content {
              key = ip_set_references.key
              ip_set_reference {
                reference_arn = ip_set_references.value.reference_arn
              }
            }
          }
        }
      }
      dynamic "rule_variables" {
        for_each = rule_group.value.rule_variables == null ? [] : [rule_group.value.rule_variables]
        content {
          dynamic "ip_sets" {
            for_each = rule_variables.value.ip_sets
            content {
              key = ip_sets.key
              ip_set {
                definition = ip_sets.value.definition
              }
            }
          }
          dynamic "port_sets" {
            for_each = rule_variables.value.port_sets
            content {
              key = port_sets.key
              port_set {
                definition = port_sets.value.definition
              }
            }
          }
        }
      }
      rules_source {
        rules_string = rule_group.value.rules_source.rules_string
        dynamic "rules_source_list" {
          for_each = rule_group.value.rules_source.rules_source_list == null ? [] : [rule_group.value.rules_source.rules_source_list]
          content {
            generated_rules_type = rules_source_list.value.generated_rules_type
            target_types         = rules_source_list.value.target_types
            targets              = rules_source_list.value.targets
          }
        }
        dynamic "stateful_rule" {
          for_each = rule_group.value.rules_source.stateful_rule
          content {
            action = stateful_rule.value.action
            header {
              destination      = stateful_rule.value.header.destination
              destination_port = stateful_rule.value.header.destination_port
              direction        = stateful_rule.value.header.direction
              protocol         = stateful_rule.value.header.protocol
              source           = stateful_rule.value.header.source
              source_port      = stateful_rule.value.header.source_port
            }
            dynamic "rule_option" {
              for_each = stateful_rule.value.rule_option
              content {
                keyword  = rule_option.value.keyword
                settings = rule_option.value.settings
              }
            }
          }
        }
      }
      dynamic "stateful_rule_options" {
        for_each = rule_group.value.stateful_rule_options == null ? [] : [rule_group.value.stateful_rule_options]
        content {
          rule_order = stateful_rule_options.value.rule_order
        }
      }
    }
  }
  tags = each.value.tags
}
##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Stateless rule groups use strongly typed 5-tuple match attributes and optional CloudWatch metric
# custom actions. Priority remains explicit because it defines packet evaluation order.
resource "aws_networkfirewall_rule_group" "stateless" {
  for_each    = local.stateless_rule_groups
  capacity    = each.value.capacity
  description = each.value.description
  name        = each.value.name
  type        = "STATELESS"
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      key_id = encryption_configuration.value.key_id
      type   = encryption_configuration.value.type
    }
  }
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        dynamic "custom_action" {
          for_each = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.custom_action
          content {
            action_definition {
              publish_metric_action {
                dynamic "dimension" {
                  for_each = custom_action.value.dimensions
                  content {
                    value = dimension.value
                  }
                }
              }
            }
            action_name = custom_action.key
          }
        }
        dynamic "stateless_rule" {
          for_each = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule
          content {
            priority = stateless_rule.value.priority
            rule_definition {
              actions = stateless_rule.value.rule_definition.actions
              match_attributes {
                dynamic "destination" {
                  for_each = stateless_rule.value.rule_definition.match_attributes.destination
                  content {
                    address_definition = destination.value.address_definition
                  }
                }
                dynamic "destination_port" {
                  for_each = stateless_rule.value.rule_definition.match_attributes.destination_port
                  content {
                    from_port = destination_port.value.from_port
                    to_port   = coalesce(destination_port.value.to_port, destination_port.value.from_port)
                  }
                }
                protocols = stateless_rule.value.rule_definition.match_attributes.protocols
                dynamic "source" {
                  for_each = stateless_rule.value.rule_definition.match_attributes.source
                  content {
                    address_definition = source.value.address_definition
                  }
                }
                dynamic "source_port" {
                  for_each = stateless_rule.value.rule_definition.match_attributes.source_port
                  content {
                    from_port = source_port.value.from_port
                    to_port   = coalesce(source_port.value.to_port, source_port.value.from_port)
                  }
                }
                dynamic "tcp_flag" {
                  for_each = stateless_rule.value.rule_definition.match_attributes.tcp_flag
                  content {
                    flags = tcp_flag.value.flags
                    masks = tcp_flag.value.masks
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  tags = each.value.tags
}
