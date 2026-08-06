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
# the administrator entry point and accepts management traffic only through
# the security group attached to the Client VPN association.
# Purpose: Creates the ingress and egress rules that enforce tier-level access.
# Change when: Change protocol, ports, or source only when the approved access policy changes.
module "security_group_rule" {

  source = "../../modules/security-group-rule"

  rules = {

    # Purpose: Allows SSH to the management host from the Client VPN entry security group.
    # Change when: Change the source only when the Client VPN security-group design changes.
    management-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ssh.ip_protocol
      from_port   = local.security_groups.rules.management_ssh.from_port
      to_port     = local.security_groups.rules.management_ssh.to_port

      references = [
        module.security_group.security_group_ids["management"]
      ]
    }

    # Purpose: Allows ICMP echo requests to the management host for connectivity testing.
    # Change when: Remove or narrow this rule when ping testing is no longer required.
    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ping.ip_protocol
      from_port   = local.security_groups.rules.management_ping.from_port
      to_port     = local.security_groups.rules.management_ping.to_port

      references = [
        module.security_group.security_group_ids["management"]
      ]
    }

    # Purpose: Allows the management tier to initiate outbound traffic permitted by routing and downstream controls.
    # Change when: Narrow the destination and protocol after the required management flows are confirmed.
    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.management_egress.cidr_ipv4
    }

    # Purpose: Allows SSH to Core Recovery from the Recovery Access VPC.
    # Change when: Change the source CIDR or port only when the administrative path changes.
    core-ssh-from-recovery-access = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_ssh.ip_protocol
      from_port   = local.security_groups.rules.core_ssh.from_port
      to_port     = local.security_groups.rules.core_ssh.to_port

      cidr_ipv4 = module.recovery_access.vpc_cidr
    }

    # Purpose: Allows SSH to Core Recovery from the Protected Data VPC.
    # Change when: Change the source CIDR or port only when the approved reverse path changes.
    core-ssh-from-protected-data = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_ssh.ip_protocol
      from_port   = local.security_groups.rules.core_ssh.from_port
      to_port     = local.security_groups.rules.core_ssh.to_port

      cidr_ipv4 = module.protected_data.vpc_cidr
    }

    # Purpose: Allows the Core tier to initiate outbound traffic permitted by routing and downstream controls.
    # Change when: Narrow destinations and protocols after the required recovery-service flows are confirmed.
    core-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = local.security_groups.rules.core_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.core_egress.cidr_ipv4
    }

    # Purpose: Allows SSH to Protected Data from the Core Recovery VPC.
    # Change when: Change the source CIDR or port only when the approved trust path changes.
    protected-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = local.security_groups.rules.protected_ssh.ip_protocol
      from_port   = local.security_groups.rules.protected_ssh.from_port
      to_port     = local.security_groups.rules.protected_ssh.to_port

      cidr_ipv4 = module.core_recovery.vpc_cidr
    }

    # Purpose: Allows the Protected Data tier to initiate outbound traffic permitted by routing and downstream controls.
    # Change when: Narrow destinations and protocols after the required workload flows are confirmed.
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

# Purpose: Creates the customer-managed KMS key used by supported Sandbox services.
# Change when: Change alias, rotation, or policy only through approved key-management requirements.
module "kms" {
  source = "../../modules/kms"

  description = local.kms.description

  alias = local.kms.alias

  tags = local.org_tags
}