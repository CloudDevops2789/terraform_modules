##################################################################################################
# Generic Security Groups
##################################################################################################

locals {
  configured_security_group_definitions = {
    for security_group_key, security_group in var.security_groups :
    security_group_key => {
      name = coalesce(
        security_group.name,
        var.security_group_naming_mode == "standard"
        ? "${local.name_prefix}-${replace(security_group_key, "_", "-")}-sg"
        : security_group_key
      )

      description = security_group.description
      vpc_id      = module.vpc[security_group.vpc_key].vpc_id
      tags        = security_group.tags
    }
  }
}

module "security_group" {
  source = "../../modules/security-group"

  security_groups = merge(
    local.configured_security_group_definitions,
    local.ssm_endpoint_security_group_definitions
  )

  tags = local.org_tags
}

##################################################################################################
# Generic Security-Group Policy Resolution
##################################################################################################

locals {
  security_group_vpc_cidrs = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.vpc_cidr
  }

  resolved_security_group_rules = {
    for rule in var.security_group_rules :
    rule.name => {
      type        = rule.direction
      description = rule.description

      security_group_id = (
        module.security_group.security_group_ids[
          rule.security_group
        ]
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
        ? module.security_group.security_group_ids[rule.peer]
        : null
      )
    }

    if(
      rule.enabled &&
      (
        !contains(
          var.ssh_key_access_rule_names,
          rule.name
        ) ||
        var.ssh_key_access_enabled
      )
    )
  }
}

module "security_group_rule" {
  source = "../../modules/security-group-rule"

  rules = merge(
    local.resolved_security_group_rules,
    local.ssm_endpoint_security_group_rules
  )
}
