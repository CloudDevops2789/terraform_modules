##################################################################################################
# Client VPN
##################################################################################################

# Purpose: Creates AWS Client VPN, target-network associations, authorization rules, and optional routes.
# Change when: Change certificates, the client address pool, or authorized destinations through environment inputs.
module "client_vpn" {
  source = "../../modules/client-vpn"

  name = local.client_vpn.name

  authentication_type = var.authentication_type

  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn
  saml_provider_arn          = var.saml_provider_arn

  client_cidr_block = local.client_vpn.client_cidr_block
  vpc_id            = module.recovery_access.vpc_id

  network_associations = {
    for key, subnet in module.recovery_access.subnets :
    key => {
      subnet_id = subnet.id
    }
    if subnet.group == "client-vpn"
  }

  security_group_ids = [
    module.security_group.security_group_ids["management"],
  ]

  split_tunnel       = local.client_vpn.split_tunnel
  transport_protocol = local.client_vpn.transport_protocol
  vpn_port           = local.client_vpn.vpn_port
  dns_servers        = local.client_vpn.dns_servers

  session_timeout_hours = local.client_vpn.session_timeout_hours

  authorization_rules = {
    # Purpose: Authorizes authenticated VPN users to reach the Recovery Access VPC.
    # Change when: Change the destination or user-group scope only when Client VPN access policy changes.
    recovery_access = {
      target_network_cidr  = module.recovery_access.vpc_cidr
      authorize_all_groups = local.client_vpn.authorize_all_groups
    }
  }

  # No direct Client VPN route to Core Recovery or Protected Data.
  routes = {}

  tags = local.org_tags
}
