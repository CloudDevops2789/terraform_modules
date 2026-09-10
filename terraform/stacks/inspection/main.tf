##################################################################################################
# AWS Network Firewall Inspection Composition
##################################################################################################
#
# Lifecycle ownership target
# --------------------------
# Inspection will own:
#
#   - Network Firewall stateful rule groups
#   - Network Firewall policy
#   - AWS Network Firewall
#   - CloudWatch log groups used by Network Firewall
#   - Network Firewall logging configuration
#
# Platform continues to own:
#
#   - Inspection VPC
#   - firewall and Transit Gateway subnets
#   - Transit Gateway
#   - VPC attachments
#   - base Platform routing
#
# IMPORTANT
# ---------
# The composition is staged here before Terraform state ownership is moved.
# Until that migration is completed, Platform remains the authoritative owner
# of the existing AWS Network Firewall resources.
#
# Do not apply this root against an existing Platform-owned firewall.
##################################################################################################

##################################################################################################
# Logical Firewall Zones
##################################################################################################
#
# Firewall policy uses logical IRE zone names rather than embedding environment
# CIDRs in the rule definitions.
#
# Platform owns network allocation and exports those CIDRs through
# inspection_contract.
##################################################################################################

locals {
  network_firewall_zone_cidrs = {
    recovery_access = local.network_cidrs.recovery_access
    core_recovery   = local.network_cidrs.core_recovery
    protected_data  = local.network_cidrs.protected_data
    any             = "any"
  }

  network_firewall_rules_string = join("\n", [
    for rule in var.network_firewall_rules :
    "${rule.action} ${rule.protocol} ${local.network_firewall_zone_cidrs[rule.source_zone]} ${rule.source_port} -> ${local.network_firewall_zone_cidrs[rule.destination_zone]} ${rule.destination_port} (msg:\"${rule.description}\"; sid:${rule.sid}; rev:1;)"
    if rule.enabled
  ])
}

##################################################################################################
# Stateful Segmentation Rule Group
##################################################################################################

locals {
  network_firewall_stateful_rule_groups = {
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

module "network_firewall_rule_groups" {
  source = "../../modules/network-firewall-rule-group"

  stateful_rule_groups  = local.network_firewall_stateful_rule_groups
  stateless_rule_groups = {}

  tags = local.org_tags
}

##################################################################################################
# Centralized Inspection Firewall Policy
##################################################################################################
#
# All stateless traffic is forwarded into the stateful engine. STRICT_ORDER
# preserves the approved rule sequence from inspection.tfvars.
##################################################################################################

locals {
  network_firewall_policies = {
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

  firewall_policies = local.network_firewall_policies
  tags              = local.org_tags
}

##################################################################################################
# Centralized AWS Network Firewall
##################################################################################################
#
# Firewall subnet placement comes exclusively from the Platform-owned
# inspection_contract. Inspection does not discover or recreate Platform
# topology by AWS resource name.
##################################################################################################

module "network_firewall" {
  source = "../../modules/network-firewall"

  firewalls = {
    inspection = {
      name = local.resource_names.network_firewall

      description = "Centralized inspection firewall for the AWS ${var.naming.project_display_name} ${var.naming.environment_display_name}."

      firewall_policy_arn = (
        module.network_firewall_policy
        .firewall_policy_arns["centralized_inspection"]
      )

      vpc_id = var.inspection_contract.inspection_vpc.vpc_id

      subnet_mappings = {
        for availability_zone, subnet in var.inspection_contract.inspection_vpc.firewall_subnets_by_az :
        availability_zone => {
          subnet_id       = subnet.subnet_id
          ip_address_type = "IPV4"
        }
      }

      enabled_analysis_types = [
        "HTTP_HOST",
        "TLS_SNI"
      ]

      delete_protection                 = false
      firewall_policy_change_protection = false
      subnet_change_protection          = false

      tags = {
        org_service_name = "centralized-network-inspection"
      }
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Network Firewall CloudWatch Logging
##################################################################################################
#
# ALERT and FLOW logging preserves the existing Platform configuration:
#
#   retention = 30 days
#   optional Persistent-owned customer-managed KMS key
#   monitoring dashboard disabled
#
# TLS logging is not configured because TLS decryption is not currently part of
# the Sandbox inspection policy.
##################################################################################################

locals {
  network_firewall_logging = {
    retention_in_days = 30

    log_groups = {
      alert = {
        name     = "${local.resource_names.network_firewall_log_group_prefix}/alert"
        log_type = "ALERT"
      }

      flow = {
        name     = "${local.resource_names.network_firewall_log_group_prefix}/flow"
        log_type = "FLOW"
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "network_firewall" {
  for_each = (
    var.network_firewall_logging_enabled
    ? local.network_firewall_logging.log_groups
    : {}
  )

  name              = each.value.name
  retention_in_days = local.network_firewall_logging.retention_in_days
  kms_key_id        = local.network_firewall_logging_kms_key_arn

  tags = merge(
    local.org_tags,
    {
      org_service_name = "network-firewall-logging"
      org_log_type     = lower(each.value.log_type)
    }
  )
}

module "network_firewall_logging" {
  source = "../../modules/network-firewall-logging"

  logging_configurations = (
    var.network_firewall_logging_enabled
    ? {
      inspection = {
        firewall_arn = (
          module.network_firewall
          .firewall_arns["inspection"]
        )

        enable_monitoring_dashboard = false

        destinations = {
          for destination_key, destination in local.network_firewall_logging.log_groups :
          destination_key => {
            log_type = destination.log_type

            cloudwatch_logs = {
              log_group_name = (
                aws_cloudwatch_log_group
                .network_firewall[destination_key]
                .name
              )
            }
          }
        }
      }
    }
    : {}
  )
}
