################################################################################
# AWS Managed Microsoft AD
#
# Lifecycle ownership:
#   Identity state owns the directory.
#
# Input flow:
#   identity.tfvars / approved AAP runtime values
#       -> variables.tf
#       -> locals.tf placement resolution
#       -> module.managed_microsoft_ad below
#
# Platform dependency:
#   Platform outputs.tf
#       -> Platform Terraform state
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> var.platform_contract
#       -> local.identity_platform_placement
#
# Sensitive input:
#   var.managed_ad_password is credential-owned and injected through AAP.
#
# This stack does not hardcode VPC IDs, subnet IDs, CIDRs, or AZs.
################################################################################

module "managed_microsoft_ad" {
  count = var.managed_ad_enabled ? 1 : 0

  source = "../../modules/managed-microsoft-ad"

  domain_name = try(var.managed_ad_configuration.domain_name, "")
  short_name  = try(var.managed_ad_configuration.short_name, null)
  password    = var.managed_ad_password
  edition     = try(var.managed_ad_configuration.edition, "Standard")

  enable_directory_data_access = try(
    var.managed_ad_configuration.enable_directory_data_access,
    false
  )

  vpc_id     = try(local.identity_platform_placement.vpc_id, "")
  subnet_ids = try(local.identity_platform_placement.subnet_ids, [])

  client_cidr_blocks = (
    var.platform_contract == null
    ? []
    : [
      for vpc_key in sort(tolist(var.managed_ad_client_vpc_keys)) :
      var.platform_contract.vpc_cidrs[vpc_key]
      if vpc_key != try(var.identity_placement.vpc_key, null)
    ]
  )

  tags = local.org_tags
}


################################################################################
# Private DNS Forwarding to AWS Managed Microsoft AD
#
# Purpose:
#   Provides optional outbound Route 53 Resolver forwarding to the Managed AD
#   DNS namespace.
#
# Placement:
#   var.platform_contract
#       -> local.managed_ad_dns_resolver_placement
#
# Internal dependency:
#   module.managed_microsoft_ad
#       -> directory_name
#       -> dns_ip_addresses
#       -> security_group_id
#       -> Resolver security rules and forwarding configuration
#
# This keeps DNS integration inside the Identity lifecycle because it depends
# directly on the directory's runtime outputs.
################################################################################

module "managed_ad_dns_security_group" {
  count = local.managed_ad_dns_resolver_enabled ? 1 : 0

  source = "../../modules/security-group"

  security_groups = {
    resolver = {
      name = try(
        coalesce(
          var.managed_ad_dns_resolver.security_group_name,
          "${var.managed_ad_dns_resolver.endpoint_name}-sg"
        ),
        null
      )

      description = "Private Route 53 Resolver access to the managed directory DNS service"
      vpc_id      = local.managed_ad_dns_resolver_placement.vpc_id
    }
  }

  tags = local.org_tags
}

module "managed_ad_dns_security_group_rules" {
  count = local.managed_ad_dns_resolver_enabled ? 1 : 0

  source = "../../modules/security-group-rule"

  rules = {
    resolver-dns-tcp-egress = {
      type                         = "egress"
      security_group_id            = module.managed_ad_dns_security_group[0].security_group_ids["resolver"]
      description                  = "DNS over TCP to AWS Managed Microsoft AD"
      ip_protocol                  = "tcp"
      from_port                    = 53
      to_port                      = 53
      referenced_security_group_id = module.managed_microsoft_ad[0].security_group_id
    }

    resolver-dns-udp-egress = {
      type                         = "egress"
      security_group_id            = module.managed_ad_dns_security_group[0].security_group_ids["resolver"]
      description                  = "DNS over UDP to AWS Managed Microsoft AD"
      ip_protocol                  = "udp"
      from_port                    = 53
      to_port                      = 53
      referenced_security_group_id = module.managed_microsoft_ad[0].security_group_id
    }

    directory-dns-tcp-ingress = {
      type                         = "ingress"
      security_group_id            = module.managed_microsoft_ad[0].security_group_id
      description                  = "DNS over TCP from the private Route 53 Resolver"
      ip_protocol                  = "tcp"
      from_port                    = 53
      to_port                      = 53
      referenced_security_group_id = module.managed_ad_dns_security_group[0].security_group_ids["resolver"]
    }

    directory-dns-udp-ingress = {
      type                         = "ingress"
      security_group_id            = module.managed_microsoft_ad[0].security_group_id
      description                  = "DNS over UDP from the private Route 53 Resolver"
      ip_protocol                  = "udp"
      from_port                    = 53
      to_port                      = 53
      referenced_security_group_id = module.managed_ad_dns_security_group[0].security_group_ids["resolver"]
    }
  }
}

module "managed_ad_dns_resolver" {
  count = local.managed_ad_dns_resolver_enabled ? 1 : 0

  source = "../../modules/route53-resolver"

  name               = try(var.managed_ad_dns_resolver.endpoint_name, "")
  direction          = "OUTBOUND"
  subnet_ids         = local.managed_ad_dns_resolver_placement.subnet_ids
  security_group_ids = [module.managed_ad_dns_security_group[0].security_group_ids["resolver"]]

  forwarding_rules = {
    managed_ad = {
      name        = try(var.managed_ad_dns_resolver.rule_name, "")
      domain_name = module.managed_microsoft_ad[0].directory_name

      target_ips = [
        for dns_ip_address in module.managed_microsoft_ad[0].dns_ip_addresses :
        { ip = dns_ip_address }
      ]

      vpc_ids = {
        for vpc_key in sort(tolist(try(var.managed_ad_dns_resolver.associated_vpc_keys, toset([])))) :
        vpc_key => try(var.platform_contract.vpc_ids[vpc_key], "")
      }
    }
  }

  query_log_config_id = try(var.managed_ad_dns_resolver.query_log_config_id, null)

  query_log_vpc_ids = {
    for vpc_key in sort(tolist(try(var.managed_ad_dns_resolver.query_log_vpc_keys, toset([])))) :
    vpc_key => try(var.platform_contract.vpc_ids[vpc_key], "")
  }

  tags = local.org_tags

  depends_on = [module.managed_ad_dns_security_group_rules]
}
