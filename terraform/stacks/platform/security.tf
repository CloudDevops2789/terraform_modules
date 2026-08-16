##################################################################################################
# Security
##################################################################################################

############################################
# Security Groups
############################################
# One security group per trust tier (management, core, protected).
# Grouping rules by tier - rather than by instance - keeps the security
# posture legible: each tier's allowed traffic maps directly to the
# IRE trust chain enforced by the Transit Gateway route tables above.
# Purpose: Creates one security group for each Sandbox trust tier.
# Change when: Add or move a group only when the workload trust boundary changes.
module "security_group" {

  source = "../../modules/security-group"

  tags = local.org_tags
  security_groups = merge(
    {
      management = {
        description = local.security_groups.tiers.management.description
        vpc_id      = module.recovery_access.vpc_id
      }

      core = {
        description = local.security_groups.tiers.core.description
        vpc_id      = module.core_recovery.vpc_id
      }

      protected = {
        description = local.security_groups.tiers.protected.description
        vpc_id      = module.protected_data.vpc_id
      }
    },
    var.ssm_management_plane_enabled ? {
      ssm_recovery_access = {
        description = "Private Systems Manager endpoints for Recovery Access"
        vpc_id      = module.recovery_access.vpc_id
      }

      ssm_core_recovery = {
        description = "Private Systems Manager endpoints for Core Recovery"
        vpc_id      = module.core_recovery.vpc_id
      }

      ssm_protected_data = {
        description = "Private Systems Manager endpoints for Protected Data"
        vpc_id      = module.protected_data.vpc_id
      }
    } : {}
  )

}

##################################################################################################
# Security Group Policy Resolution
##################################################################################################
# Security-group rules use logical names in the environment policy rather than
# hard-coded AWS security group IDs or VPC CIDRs.
#
# Terraform resolves:
#
#   security_group = "core"
#       -> actual Core security group ID
#
#   peer_type = "vpc"
#   peer      = "recovery_access"
#       -> actual Recovery Access VPC CIDR
#
# This keeps the security policy portable when AWS-generated IDs or environment
# network allocations change.

locals {
  security_group_ids_by_tier = {
    management = module.security_group.security_group_ids["management"]
    core       = module.security_group.security_group_ids["core"]
    protected  = module.security_group.security_group_ids["protected"]
  }

  security_group_vpc_cidrs = {
    recovery_access = module.recovery_access.vpc_cidr
    core_recovery   = module.core_recovery.vpc_cidr
    protected_data  = module.protected_data.vpc_cidr
  }

  # SSH rules used by the representative validation workloads are activated
  # only when the demonstration lifecycle explicitly selects SSH-key access.
  demo_ssh_security_group_rule_names = toset([
    "management-ssh-from-client-vpn",
    "management-ssh-from-core",
    "core-ssh-from-recovery-access",
    "core-ssh-from-protected-data",
    "protected-ssh",
  ])

  sandbox_security_group_rules = {
    for rule in var.security_group_rules :
    rule.name => {
      type        = rule.direction
      description = rule.description

      security_group_id = (
        local.security_group_ids_by_tier[rule.security_group]
      )

      ip_protocol = rule.protocol
      from_port   = rule.from_port
      to_port     = rule.to_port

      cidr_ipv4 = (
        rule.peer_type == "vpc"
        ? local.security_group_vpc_cidrs[rule.peer]
        : rule.peer_type == "cidr"
        ? rule.peer
        : null
      )

      referenced_security_group_id = (
        rule.peer_type == "security_group"
        ? local.security_group_ids_by_tier[rule.peer]
        : null
      )
    }
    if rule.enabled && (
      !contains(local.demo_ssh_security_group_rule_names, rule.name) ||
      (var.demo_ec2_enabled && var.demo_ec2_access_method == "ssh_key")
    )
  }
}

##################################################################################################
# Security Group Rules
##################################################################################################
# Purpose:
# Creates security-group rules from the environment security policy.
#
# Rule definitions are supplied through var.security_group_rules using logical
# trust-tier and network-zone names. This block resolves those names into the
# AWS resource IDs and CIDRs required by the reusable rule module.
#
# Change when:
# Modify the security-group policy rather than adding hard-coded rules here.

module "security_group_rule" {
  source = "../../modules/security-group-rule"

  rules = merge(
    local.sandbox_security_group_rules,
    local.ssm_endpoint_security_group_rules
  )
}
