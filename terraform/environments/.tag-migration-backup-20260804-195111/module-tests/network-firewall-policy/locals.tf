locals {
  ##################################################################################################
  # Common Tags
  ##################################################################################################
  default_tags = {
    TestedModule = "network-firewall-policy"
  }
  ##################################################################################################
  # Supporting Rule Groups
  ##################################################################################################
  # These rule groups exist only to provide real ARNs and rule-order compatibility to the policy
  # module test. The previously validated rule-group module creates them.
  supporting_stateful_rule_groups = {
    strict_suricata = {
      name        = "module-test-policy-strict-suricata"
      description = "Supporting strict-order stateful rule group for policy validation."
      capacity    = 10
      rule_group = {
        rule_variables = {
          ip_sets = {
            HOME_NET = {
              definition = ["10.250.0.0/16"]
            }
          }
        }
        rules_source = {
          rules_string = <<-EOT
            alert tcp $HOME_NET any -> any 443 (msg:"Policy module test TLS observation"; flow:to_server; sid:2000001; rev:1;)
          EOT
        }
        stateful_rule_options = {
          rule_order = "STRICT_ORDER"
        }
      }
    }
  }
  supporting_stateless_rule_groups = {
    baseline = {
      name        = "module-test-policy-stateless-baseline"
      description = "Supporting stateless rule group for policy validation."
      capacity    = 10
      rule_group = {
        rules_source = {
          stateless_rules_and_custom_actions = {
            stateless_rule = [{
              priority = 100
              rule_definition = {
                actions = ["aws:forward_to_sfe"]
                match_attributes = {
                  source = [{
                    address_definition = "10.250.0.0/16"
                  }]
                  destination = [{
                    address_definition = "0.0.0.0/0"
                  }]
                  protocols = [6]
                }
              }
            }]
          }
        }
      }
    }
  }
  ##################################################################################################
  # Firewall Policies
  ##################################################################################################
  firewall_policies = {
    strict_inspection = {
      name        = "module-test-strict-inspection-policy"
      description = "Validates strict ordering, rule references, policy variables, and metrics."
      firewall_policy = {
        policy_variables = {
          rule_variables = {
            HOME_NET = {
              definition = ["10.250.0.0/16"]
            }
          }
        }
        stateful_engine_options = {
          rule_order              = "STRICT_ORDER"
          stream_exception_policy = "DROP"
          flow_timeouts = {
            tcp_idle_timeout_seconds = 350
          }
        }
        stateful_default_actions = [
          "aws:drop_strict",
          "aws:alert_strict"
        ]
        stateful_rule_group_references = {
          strict_suricata = {
            priority     = 100
            resource_arn = module.supporting_rule_groups.stateful_rule_group_arns["strict_suricata"]
          }
        }
        stateless_custom_actions = {
          PublishPolicyDefaultMetric = {
            dimensions = ["PolicyDefaultTraffic"]
          }
        }
        stateless_default_actions = [
          "aws:forward_to_sfe",
          "PublishPolicyDefaultMetric"
        ]
        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
        stateless_rule_group_references = {
          baseline = {
            priority     = 100
            resource_arn = module.supporting_rule_groups.stateless_rule_group_arns["baseline"]
          }
        }
      }
    }
    default_action_order = {
      name        = "module-test-default-action-order-policy"
      description = "Validates the minimal default-action-order policy path."
      firewall_policy = {
        stateless_default_actions = [
          "aws:pass"
        ]
        stateless_fragment_default_actions = [
          "aws:drop"
        ]
      }
    }
  }
}
