################################################################################
# Identity Stack Derived Values
#
# Terraform loads all *.tf files in this directory as one root module.
# main.tf does not call locals.tf or variables.tf; references form the
# dependency graph.
#
# Key dependency chain:
#
#   Platform outputs.tf
#       -> Platform Terraform state
#       -> AAP dependency reader
#       -> AAP runtime contract
#       -> var.platform_contract
#       -> locals below
#       -> main.tf
################################################################################

locals {
  ##############################################################################
  # Organization Tags
  #
  # Sources:
  #   organization tagging variables declared in variables.tf
  #
  # Consumers:
  #   provider.tf default_tags
  #   main.tf module-specific tags
  ##############################################################################

  org_tags = var.organization_tags

  ##############################################################################
  # Managed AD Placement Resolution
  #
  # Inputs:
  #   var.platform_contract
  #   var.identity_placement
  #
  # The Platform contract provides topology-independent VPC and subnet maps.
  # identity_placement selects the logical VPC and subnet group used by Managed
  # Microsoft AD without hardcoding VPC IDs, subnet IDs, CIDRs, or AZs.
  #
  # Consumer:
  #   module.managed_microsoft_ad in main.tf
  ##############################################################################

  identity_platform_placement = (
    var.platform_contract == null ||
    var.identity_placement == null
    ? null
    : {
      vpc_id = (
        var.platform_contract.vpc_ids[
          var.identity_placement.vpc_key
        ]
      )

      subnet_ids = slice(
        var.platform_contract.subnet_ids_by_group[
          var.identity_placement.vpc_key
          ][
          var.identity_placement.subnet_group
        ],
        0,
        var.identity_placement.required_subnet_count
      )
    }
  )

  ##############################################################################
  # Managed AD DNS Resolver Enablement
  #
  # Resolver integration is active only when:
  #   Managed AD is enabled
  #   managed_ad_dns_resolver is configured
  #   managed_ad_dns_resolver.enabled is true
  ##############################################################################

  managed_ad_dns_resolver_enabled = (
    var.managed_ad_enabled &&
    var.managed_ad_dns_resolver != null &&
    try(var.managed_ad_dns_resolver.enabled, false)
  )

  ##############################################################################
  # Route 53 Resolver Placement
  #
  # Inputs:
  #   var.platform_contract
  #   var.managed_ad_dns_resolver
  #
  # Consumer:
  #   DNS Resolver composition in main.tf
  ##############################################################################

  managed_ad_dns_resolver_placement = (
    !local.managed_ad_dns_resolver_enabled
    ? null
    : {
      vpc_id = var.platform_contract.vpc_ids[
        var.managed_ad_dns_resolver.vpc_key
      ]

      subnet_ids = slice(
        var.platform_contract.subnet_ids_by_group[
          var.managed_ad_dns_resolver.vpc_key
          ][
          var.managed_ad_dns_resolver.subnet_group
        ],
        0,
        var.managed_ad_dns_resolver.required_subnet_count
      )
    }
  )
}
