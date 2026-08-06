##################################################################################################
# Network Firewall Stateful Segmentation Rules
##################################################################################################
# These rules reinforce the approved IRE trust relationships:
#
# Recovery Access <-> Core Recovery <-> Protected Data
#
# Recovery Access and Protected Data are deliberately not permitted to communicate directly.
# Security groups continue to enforce workload-level protocol and port restrictions.

locals {
  sandbox_network_firewall_stateful_rule_groups = {
    ire_segmentation = {
      name        = local.resource_names.network_firewall_rule_group
      description = "Strict-order IRE trust-boundary rules for centralized inspection."
      capacity    = 100

      rule_group = {
        rule_variables = {
          ip_sets = {
            HOME_NET = {
              definition = [local.network_cidrs.account]
            }
          }
        }

        rules_source = {
          rules_string = <<-EOT
            pass ip ${local.network_cidrs.recovery_access} any -> ${local.network_cidrs.core_recovery} any (msg:"Allow Recovery Access to Core Recovery"; sid:3100001; rev:1;)
            pass ip ${local.network_cidrs.core_recovery} any -> ${local.network_cidrs.recovery_access} any (msg:"Allow Core Recovery to Recovery Access"; sid:3100002; rev:1;)
            pass ip ${local.network_cidrs.core_recovery} any -> ${local.network_cidrs.protected_data} any (msg:"Allow Core Recovery to Protected Data"; sid:3100003; rev:1;)
            pass ip ${local.network_cidrs.protected_data} any -> ${local.network_cidrs.core_recovery} any (msg:"Allow Protected Data to Core Recovery"; sid:3100004; rev:1;)
          EOT
        }

        stateful_rule_options = {
          rule_order = "STRICT_ORDER"
        }
      }

      tags = {
        org_service_name = "centralized-network-inspection"
      }
    }
  }
}

module "network_firewall_rule_groups" {
  source = "../../modules/network-firewall-rule-group"

  stateful_rule_groups  = local.sandbox_network_firewall_stateful_rule_groups
  stateless_rule_groups = {}

  tags = local.org_tags
}
