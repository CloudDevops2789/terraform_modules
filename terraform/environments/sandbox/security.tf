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
module "security_group" {

  source = "../../modules/security-group"

  default_tags = local.default_tags

  security_groups = {

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

  }

}

############################################
# Security Group Rules
############################################
# Ingress/egress rules for each tier's security group. Ingress is scoped
# to the CIDR of the adjacent, trusted VPC only (e.g. Protected Data only
# accepts SSH from Core Recovery), mirroring the no-direct-path rule
# enforced at the network layer. Management is the exception, since it is
# the administrator entry point and is reachable from 0.0.0.0/0 in this
# sandbox configuration.
module "security_group_rule" {

  source = "../../modules/security-group-rule"

  rules = {

    management-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ssh.ip_protocol
      from_port   = local.security_groups.rules.management_ssh.from_port
      to_port     = local.security_groups.rules.management_ssh.to_port

      cidr_ipv4 = local.security_groups.rules.management_ssh.cidr_ipv4
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ping.ip_protocol
      from_port   = local.security_groups.rules.management_ping.from_port
      to_port     = local.security_groups.rules.management_ping.to_port

      cidr_ipv4 = local.security_groups.rules.management_ping.cidr_ipv4
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.management_egress.cidr_ipv4
    }

    core-ssh-from-recovery-access = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_ssh.ip_protocol
      from_port   = local.security_groups.rules.core_ssh.from_port
      to_port     = local.security_groups.rules.core_ssh.to_port

      cidr_ipv4 = module.recovery_access.vpc_cidr
    }

    core-ssh-from-protected-data = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_ssh.ip_protocol
      from_port   = local.security_groups.rules.core_ssh.from_port
      to_port     = local.security_groups.rules.core_ssh.to_port

      cidr_ipv4 = module.protected_data.vpc_cidr
    }

    core-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.core_egress.cidr_ipv4
    }

    protected-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = local.security_groups.rules.protected_ssh.ip_protocol
      from_port   = local.security_groups.rules.protected_ssh.from_port
      to_port     = local.security_groups.rules.protected_ssh.to_port

      cidr_ipv4 = module.core_recovery.vpc_cidr
    }

    protected-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = local.security_groups.rules.protected_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.protected_egress.cidr_ipv4
    }

  }

}

############################################
# KMS
############################################

module "kms" {
  source = "../../modules/kms"

  description = local.kms.description

  alias = local.kms.alias

  tags = local.default_tags
}