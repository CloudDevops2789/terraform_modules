##################################################################################################
# IRE Identity Stack
##################################################################################################
#
# Placement is resolved from the approved Platform contract and environment
# configuration. This stack does not hardcode VPC, subnet, CIDR, or AZ identity.
#
##################################################################################################

module "managed_microsoft_ad" {
  count = var.managed_ad_enabled ? 1 : 0

  source = "../../modules/managed-microsoft-ad"

  domain_name = try(var.managed_ad_configuration.domain_name, "")
  password    = var.managed_ad_password
  edition     = try(var.managed_ad_configuration.edition, "Standard")

  vpc_id     = try(local.identity_platform_placement.vpc_id, "")
  subnet_ids = try(local.identity_platform_placement.subnet_ids, [])

  client_cidr_blocks = (
    var.platform_contract == null
    ? []
    : [
      for vpc_key in sort(tolist(var.managed_ad_client_vpc_keys)) :
      var.platform_contract.vpc_cidrs[vpc_key]
    ]
  )

  tags = local.org_tags
}
