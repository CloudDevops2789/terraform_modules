##################################################################################################
# Generic Identity Placement Resolution
##################################################################################################

locals {
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

  managed_ad_dns_resolver_enabled = (
    var.managed_ad_enabled &&
    var.managed_ad_dns_resolver != null &&
    try(var.managed_ad_dns_resolver.enabled, false)
  )

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
