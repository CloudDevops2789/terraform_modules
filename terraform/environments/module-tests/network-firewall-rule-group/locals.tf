locals {
  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # TestedModule distinguishes these resources from sandbox and production rule groups.
  org_required_tags = {
    org_it_cost_center       = var.org_it_cost_center
    org_department           = var.org_department
    org_cmdb_calculated_app  = var.org_cmdb_calculated_app
    org_business_criticality = var.org_business_criticality
    org_environment          = var.org_environment
    org_data_classification  = var.org_data_classification
    org_project_name         = var.org_project_name
    org_managed_by           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )
  ##################################################################################################
  # Stateful Rule Groups
  ##################################################################################################
  # The test intentionally exercises each supported stateful source path without requiring a VPC,
  # firewall policy, or firewall. Those resources are separate module responsibilities.
  stateful_rule_groups = {
    raw_suricata = {
      name        = "module-test-raw-suricata"
      description = "Validates top-level Suricata flat-format rules."
      capacity    = 10
      rules       = <<-EOT
        alert tcp any any -> any 443 (msg:"Module test TLS observation"; flow:to_server; sid:1000001; rev:1;)
      EOT
    }
    domain_denylist = {
      name        = "module-test-domain-denylist"
      description = "Validates generated stateful domain-list rules."
      capacity    = 100
      rule_group = {
        rules_source = {
          rules_source_list = {
            generated_rules_type = "DENYLIST"
            target_types         = ["HTTP_HOST", "TLS_SNI"]
            targets              = [".malicious.example"]
          }
        }
        stateful_rule_options = {
          rule_order = "DEFAULT_ACTION_ORDER"
        }
      }
    }
    structured_stateful = {
      name        = "module-test-structured-stateful"
      description = "Validates typed stateful 5-tuple rules and rule variables."
      capacity    = 10
      rule_group = {
        rule_variables = {
          ip_sets = {
            HOME_NET = {
              definition = ["10.250.0.0/16"]
            }
          }
          port_sets = {
            TLS_PORTS = {
              definition = ["443"]
            }
          }
        }
        rules_source = {
          stateful_rule = [{
            action = "ALERT"
            header = {
              destination      = "ANY"
              destination_port = "$TLS_PORTS"
              direction        = "FORWARD"
              protocol         = "TCP"
              source           = "$HOME_NET"
              source_port      = "ANY"
            }
            rule_option = [{
              keyword  = "sid"
              settings = ["1000002"]
            }]
          }]
        }
        stateful_rule_options = {
          rule_order = "STRICT_ORDER"
        }
      }
    }
  }
  ##################################################################################################
  # Stateless Rule Groups
  ##################################################################################################
  # A custom action proves that the module renders the complete metric action hierarchy while the
  # stateless rule validates addresses, ports, protocols, and TCP flags.
  stateless_rule_groups = {
    baseline = {
      name        = "module-test-stateless-baseline"
      description = "Validates typed stateless rules and custom CloudWatch metric actions."
      capacity    = 100
      rule_group = {
        rules_source = {
          stateless_rules_and_custom_actions = {
            custom_action = {
              PublishModuleTestMetric = {
                dimensions = ["ModuleTestTraffic"]
              }
            }
            stateless_rule = [{
              priority = 100
              rule_definition = {
                actions = ["aws:forward_to_sfe", "PublishModuleTestMetric"]
                match_attributes = {
                  source = [{
                    address_definition = "10.250.0.0/16"
                  }]
                  source_port = [{
                    from_port = 1024
                    to_port   = 65535
                  }]
                  destination = [{
                    address_definition = "10.251.0.0/16"
                  }]
                  destination_port = [{
                    from_port = 443
                    to_port   = 443
                  }]
                  protocols = [6]
                  tcp_flag = [{
                    flags = ["SYN"]
                    masks = ["SYN", "ACK"]
                  }]
                }
              }
            }]
          }
        }
      }
    }
  }
}
