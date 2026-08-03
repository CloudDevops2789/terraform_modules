##################################################################################################
# AWS Network Firewall Policies
##################################################################################################
# Each policy can reference customer-managed, AWS-managed, or externally shared rule groups by ARN.
# Rule groups remain separate resources so their lifecycle and ownership are not coupled to policies.
resource "aws_networkfirewall_firewall_policy" "this" {
  for_each    = local.firewall_policies
  description = each.value.description
  name        = each.value.name
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      key_id = encryption_configuration.value.key_id
      type   = encryption_configuration.value.type
    }
  }
  firewall_policy {
    enable_tls_session_holding         = each.value.firewall_policy.enable_tls_session_holding
    stateful_default_actions           = each.value.firewall_policy.stateful_default_actions
    stateless_default_actions          = each.value.firewall_policy.stateless_default_actions
    stateless_fragment_default_actions = each.value.firewall_policy.stateless_fragment_default_actions
    tls_inspection_configuration_arn   = each.value.firewall_policy.tls_inspection_configuration_arn
    dynamic "policy_variables" {
      for_each = each.value.firewall_policy.policy_variables == null ? [] : [each.value.firewall_policy.policy_variables]
      content {
        dynamic "rule_variables" {
          for_each = policy_variables.value.rule_variables
          content {
            key = rule_variables.key
            ip_set {
              definition = rule_variables.value.definition
            }
          }
        }
      }
    }
    dynamic "stateful_engine_options" {
      for_each = each.value.firewall_policy.stateful_engine_options == null ? [] : [each.value.firewall_policy.stateful_engine_options]
      content {
        rule_order              = stateful_engine_options.value.rule_order
        stream_exception_policy = stateful_engine_options.value.stream_exception_policy
        dynamic "flow_timeouts" {
          for_each = stateful_engine_options.value.flow_timeouts == null ? [] : [stateful_engine_options.value.flow_timeouts]
          content {
            tcp_idle_timeout_seconds = flow_timeouts.value.tcp_idle_timeout_seconds
          }
        }
      }
    }
    dynamic "stateful_rule_group_reference" {
      for_each = each.value.firewall_policy.stateful_rule_group_references
      content {
        deep_threat_inspection = stateful_rule_group_reference.value.deep_threat_inspection
        priority               = stateful_rule_group_reference.value.priority
        resource_arn           = stateful_rule_group_reference.value.resource_arn
        dynamic "override" {
          for_each = stateful_rule_group_reference.value.override == null ? [] : [stateful_rule_group_reference.value.override]
          content {
            action = override.value.action
          }
        }
      }
    }
    dynamic "stateless_custom_action" {
      for_each = each.value.firewall_policy.stateless_custom_actions
      content {
        action_name = stateless_custom_action.key
        action_definition {
          publish_metric_action {
            dynamic "dimension" {
              for_each = stateless_custom_action.value.dimensions
              content {
                value = dimension.value
              }
            }
          }
        }
      }
    }
    dynamic "stateless_rule_group_reference" {
      for_each = each.value.firewall_policy.stateless_rule_group_references
      content {
        priority     = stateless_rule_group_reference.value.priority
        resource_arn = stateless_rule_group_reference.value.resource_arn
      }
    }
  }
  tags = each.value.tags
}
