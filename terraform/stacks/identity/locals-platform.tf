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
}
