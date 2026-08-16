##################################################################################################
# Client VPN
##################################################################################################

module "client_vpn_saml_provider" {
  count = (
    var.client_vpn_enabled &&
    var.authentication_type == "federated" &&
    var.manage_saml_provider
  ) ? 1 : 0

  source = "../../modules/iam-saml-provider"

  name = coalesce(
    var.saml_provider_name,
    "${local.client_vpn.name}-saml"
  )

  saml_metadata_document = var.saml_metadata_document
}

module "client_vpn" {
  source = "../../modules/client-vpn"

  count = var.client_vpn_enabled ? 1 : 0

  name = local.client_vpn.name

  authentication_type = var.authentication_type

  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn
  saml_provider_arn          = local.effective_saml_provider_arn

  client_cidr_block = local.client_vpn.client_cidr_block

  vpc_id = try(
    module.vpc[
      var.client_vpn_network_binding.vpc_key
    ].vpc_id,
    null
  )

  network_associations = (
    var.client_vpn_enabled
    ? {
      for subnet_key, subnet in module.vpc[
        var.client_vpn_network_binding.vpc_key
      ].subnets :
      subnet_key => {
        subnet_id = subnet.id
      }
      if(
        subnet.group ==
        var.client_vpn_network_binding.subnet_group
      )
    }
    : {}
  )

  security_group_ids = (
    var.client_vpn_enabled
    ? [
      for security_group_key in sort(
        tolist(
          var.client_vpn_network_binding.security_group_keys
        )
      ) :
      module.security_group.security_group_ids[
        security_group_key
      ]
    ]
    : []
  )

  split_tunnel       = local.client_vpn.split_tunnel
  transport_protocol = local.client_vpn.transport_protocol
  vpn_port           = local.client_vpn.vpn_port
  dns_servers        = local.client_vpn.dns_servers

  session_timeout_hours = local.client_vpn.session_timeout_hours

  authorization_rules = (
    var.client_vpn_enabled
    ? {
      for vpc_key in var.client_vpn_network_binding.authorization_vpc_keys :
      vpc_key => {
        target_network_cidr = module.vpc[vpc_key].vpc_cidr

        authorize_all_groups = (
          local.client_vpn.authorize_all_groups
        )
      }
    }
    : {}
  )

  routes = {}

  tags = local.org_tags
}
