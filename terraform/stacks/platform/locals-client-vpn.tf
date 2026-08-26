locals {
  ##################################################################################################
  # Client VPN
  ##################################################################################################
  # Static Client VPN configuration: display name, client address pool, and
  # session/transport behaviour. VPC/subnet associations, security group
  # membership, and authorization target CIDRs describe relationships to
  # other resources and remain in client_vpn.tf.
  client_vpn = {
    name               = local.resource_names.client_vpn
    client_cidr_block  = local.network_cidrs.client_vpn
    split_tunnel       = true
    transport_protocol = "udp"
    vpn_port           = 443
    dns_servers = (
      var.client_vpn_dns_configuration.mode == "vpc_resolver"
      ? [
        cidrhost(
          var.network_config.vpcs[
            var.client_vpn_network_binding.vpc_key
          ].cidr_block,
          2
        )
      ]
      : var.client_vpn_dns_configuration.mode == "custom"
      ? var.client_vpn_dns_configuration.custom_dns_servers
      : []
    )
    session_timeout_hours = 8
    authorize_all_groups  = true
  }
}

##################################################################################################
# Client VPN SAML Provider
##################################################################################################

locals {
  resolved_saml_provider_arn = (
    !var.client_vpn_enabled ||
    var.authentication_type != "federated"
    ? null
    : var.manage_saml_provider
    ? try(module.client_vpn_saml_provider[0].saml_provider_arn, null)
    : var.saml_provider_arn
  )

  effective_saml_provider_arn = (
    var.client_vpn_enabled &&
    var.authentication_type == "federated"
    ? local.resolved_saml_provider_arn
    : null
  )
}
