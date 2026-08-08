##################################################################################################
# Module Under Test: security-group
##################################################################################################
# terraform/modules/security-group is the module this environment exists
# to validate: one security group created via the module's for_each over
# var.security_groups.
module "security_group" {

  source = "../../../modules/security-group"

  tags = local.org_tags
  security_groups = {
    management = {
      description = local.security_groups.tiers.management.description
      vpc_id      = module.vpc.vpc_id
    }
  }
}

##################################################################################################
# Module Under Test: security-group-rule
##################################################################################################
# terraform/modules/security-group-rule is validated alongside
# security-group because a rule cannot exist without a group. One ingress
# rule and one egress rule exercise both standalone rule resource types the
# module manages.
module "security_group_rule" {

  source = "../../../modules/security-group-rule"

  rules = {

    ssh-ingress = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]
      description       = "Module test SSH ingress rule"
      ip_protocol       = local.security_groups.rules.ssh_ingress.ip_protocol
      from_port         = local.security_groups.rules.ssh_ingress.from_port
      to_port           = local.security_groups.rules.ssh_ingress.to_port

      cidr_ipv4 = local.security_groups.rules.ssh_ingress.cidr_ipv4
    }

    all-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]
      description       = "Module test unrestricted egress rule"
      ip_protocol       = local.security_groups.rules.all_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.all_egress.cidr_ipv4
    }
  }
}
