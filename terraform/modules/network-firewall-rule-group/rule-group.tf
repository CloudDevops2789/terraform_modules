##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Creates one or more AWS Network Firewall stateful rule groups.
resource "aws_networkfirewall_rule_group" "stateful" {
  for_each = local.normalized_stateful_rule_groups
  capacity = each.value.capacity
  name = each.value.name
  description = try(each.value.description, null)
  type = "STATEFUL"
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      type = encryption_configuration.value.type
      key_id = try(encryption_configuration.value.key_id, null)
    }
  }
  rule_group {
    dynamic "stateful_rule_options" {
      for_each = each.value.stateful_rule_options == null ? [] : [each.value.stateful_rule_options]
      content {
        rule_order = stateful_rule_options.value.rule_order
      }
    }
    dynamic "rule_variables" {
      for_each = each.value.rule_variables == null ? [] : [each.value.rule_variables]
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
    dynamic "reference_sets" {
      for_each = each.value.reference_sets == null ? [] : [each.value.reference_sets]
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
    rules_source {
      rules_string = try(each.value.rules_source.rules_string, null)
    }
  }
  tags = var.tags
}