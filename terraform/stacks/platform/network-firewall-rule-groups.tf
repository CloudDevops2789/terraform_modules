locals {
  ################################################################################
  # Logical Firewall Zones
  ################################################################################
  # Maps portable zone names from terraform.tfvars to the CIDRs allocated by
  # network_config. Firewall policy therefore follows network allocation changes
  # without embedding environment-specific CIDRs in the rule definitions.

  network_firewall_zone_cidrs = {
    recovery_access = local.network_cidrs.recovery_access
    core_recovery   = local.network_cidrs.core_recovery
    protected_data  = local.network_cidrs.protected_data
    any             = "any"
  }

  ################################################################################
  # Generated Suricata Rules
  ################################################################################
  # The list order supplied through network_firewall_rules is preserved.
  # This is important because the firewall policy uses STRICT_ORDER.

  network_firewall_rules_string = join("\n", [
    for rule in var.network_firewall_rules :
    "${rule.action} ${rule.protocol} ${local.network_firewall_zone_cidrs[rule.source_zone]} ${rule.source_port} -> ${local.network_firewall_zone_cidrs[rule.destination_zone]} ${rule.destination_port} (msg:\"${rule.description}\"; sid:${rule.sid}; rev:1;)"
    if rule.enabled
  ])
}

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
          rules_string = local.network_firewall_rules_string
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

# Purpose: Creates the stateful firewall rules for approved Recovery Access, Core, and Protected Data paths.
# Change when: Change source, destination, protocol, or port scope only when the traffic policy changes.
module "network_firewall_rule_groups" {
  source = "../../modules/network-firewall-rule-group"
  # Make the firewall rule group optional
  stateful_rule_groups = (
    local.network_firewall_enabled
    ? local.sandbox_network_firewall_stateful_rule_groups
    : {}
  )
  stateless_rule_groups = {}

  tags = local.org_tags
}
