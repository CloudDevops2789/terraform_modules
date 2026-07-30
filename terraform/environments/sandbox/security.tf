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
      description = "Management"
      vpc_id      = module.recovery_access.vpc_id
    }

    core = {
      description = "Core Recovery"
      vpc_id      = module.core_recovery.vpc_id
    }

    protected = {
      description = "Protected Data"
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

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "icmp"
      from_port   = 8
      to_port     = -1

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

    core-ssh-from-recovery-access = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.recovery_access.vpc_cidr
    }

    core-ssh-from-protected-data = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.protected_data.vpc_cidr
    }

    core-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

    protected-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.core_recovery.vpc_cidr
    }

    protected-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

  }

}

############################################
# KMS
############################################

module "kms" {
  source = "../../modules/kms"

  description = "Customer managed KMS key for the IRE sandbox"

  alias = "ire-sandbox"

  tags = local.default_tags
}