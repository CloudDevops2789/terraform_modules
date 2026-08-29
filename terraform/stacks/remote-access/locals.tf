locals {
  required_tags = {
    "${var.organization_tag_key_prefix}it_cost_center"       = var.org_it_cost_center
    "${var.organization_tag_key_prefix}department"           = var.org_department
    "${var.organization_tag_key_prefix}cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "${var.organization_tag_key_prefix}business_criticality" = var.org_business_criticality
    "${var.organization_tag_key_prefix}environment"          = var.org_environment
    "${var.organization_tag_key_prefix}data_classification"  = var.org_data_classification
    "${var.organization_tag_key_prefix}project_name"         = var.org_project_name
    "${var.organization_tag_key_prefix}managed_by"           = var.org_managed_by
  }

  tags = merge(var.org_additional_tags, local.required_tags)

  association_vpc_id = try(
    var.platform_contract.vpc_ids[var.network_binding.vpc_key],
    null
  )

  association_vpc_cidr = try(
    var.platform_contract.vpc_cidrs[var.network_binding.vpc_key],
    null
  )

  association_subnet_ids = try(slice(
    var.platform_contract.subnet_ids_by_group[var.network_binding.vpc_key][var.network_binding.subnet_group],
    0,
    var.network_binding.required_subnet_count
  ), [])

  association_subnet_cidrs = try(slice(
    var.platform_contract.subnet_cidrs_by_group[var.network_binding.vpc_key][var.network_binding.subnet_group],
    0,
    var.network_binding.required_subnet_count
  ), [])

  dns_servers = (
    var.dns_configuration.mode == "vpc_resolver"
    ? try([cidrhost(local.association_vpc_cidr, 2)], [])
    : var.dns_configuration.mode == "managed_ad"
    ? try(var.identity_contract.dns_ip_addresses, [])
    : var.dns_configuration.custom_dns_servers
  )

  authorization_rules = !var.remote_access_enabled ? {} : {
    for vpc_key in var.authorization_vpc_keys :
    vpc_key => {
      target_network_cidr  = var.platform_contract.vpc_cidrs[vpc_key]
      authorize_all_groups = false
      access_group_id      = var.client_vpn_access_group_id
    }
  }

  routes = !var.remote_access_enabled ? {} : {
    for vpc_key in var.authorization_vpc_keys :
    vpc_key => {
      destination_cidr_block = var.platform_contract.vpc_cidrs[vpc_key]
      target_subnet_id       = local.association_subnet_ids[0]
      description            = "Remote access to approved ${vpc_key} network"
    }
    if vpc_key != var.network_binding.vpc_key
  }

  endpoint_egress_security_group_rules = !var.remote_access_enabled ? {} : {
    for rule_key, rule in var.endpoint_egress_rules :
    "endpoint-${rule_key}" => {
      type              = "egress"
      security_group_id = module.remote_access_security_group.security_group_ids["endpoint"]
      description       = rule.description
      ip_protocol       = rule.protocol
      from_port         = rule.from_port
      to_port           = rule.to_port
      cidr_ipv4         = var.platform_contract.vpc_cidrs[rule.destination_vpc_key]
    }
  }

  target_ingress_security_group_rules = !var.remote_access_enabled ? {} : {
    for item in flatten([
      for rule_key, rule in var.target_ingress_rules : [
        for index, cidr in local.association_subnet_cidrs : {
          key                = "target-${rule_key}-${index}"
          security_group_key = rule.security_group_key
          protocol           = rule.protocol
          from_port          = rule.from_port
          to_port            = rule.to_port
          description        = rule.description
          cidr               = cidr
        }
      ]
    ]) :
    item.key => {
      type              = "ingress"
      security_group_id = var.platform_contract.security_group_ids[item.security_group_key]
      description       = item.description
      ip_protocol       = item.protocol
      from_port         = item.from_port
      to_port           = item.to_port
      cidr_ipv4         = item.cidr
    }
  }
}
