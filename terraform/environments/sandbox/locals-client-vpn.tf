locals {
  ##################################################################################################
  # Client VPN
  ##################################################################################################
  # Static Client VPN configuration: display name, client address pool, and
  # session/transport behaviour. VPC/subnet associations, security group
  # membership, and authorization target CIDRs describe relationships to
  # other resources and remain in client_vpn.tf.
  client_vpn = {
    name                  = local.resource_names.client_vpn
    client_cidr_block     = local.network_cidrs.client_vpn
    split_tunnel          = true
    transport_protocol    = "udp"
    vpn_port              = 443
    dns_servers           = []
    session_timeout_hours = 8
    authorize_all_groups  = true
  }
}

##################################################################################################
# Client VPN SAML Provider
##################################################################################################

locals {
  resolved_saml_provider_arn = (
    var.manage_saml_provider
    ? module.client_vpn_saml_provider[0].saml_provider_arn
    : var.saml_provider_arn
  )

  effective_saml_provider_arn = (
    var.authentication_type == "federated"
    ? local.resolved_saml_provider_arn
    : null
  )
}
