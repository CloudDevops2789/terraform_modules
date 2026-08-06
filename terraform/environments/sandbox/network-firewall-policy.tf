##################################################################################################
# Centralized Inspection Firewall Policy
##################################################################################################
# All stateless traffic is forwarded to the stateful engine. The strict stateful rule group permits
# only the approved IRE VPC relationships. Unmatched traffic is dropped and alerted.

locals {
  sandbox_network_firewall_policies = {
    centralized_inspection = {
      name        = local.resource_names.network_firewall_policy
      description = "Strict centralized inspection policy for the AWS ${var.naming.project_display_name} ${var.naming.environment_display_name}."

      firewall_policy = {
        policy_variables = {
          rule_variables = {
            HOME_NET = {
              definition = [local.network_cidrs.account]
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
          ire_segmentation = {
            priority = 100
            resource_arn = (
              module.network_firewall_rule_groups
              .stateful_rule_group_arns["ire_segmentation"]
            )
          }
        }

        stateless_default_actions = [
          "aws:forward_to_sfe"
        ]

        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
      }

      tags = {
        org_service_name = "centralized-network-inspection"
      }
    }
  }
}

module "network_firewall_policy" {
  source = "../../modules/network-firewall-policy"

  firewall_policies = local.sandbox_network_firewall_policies
  tags              = local.org_tags
}
