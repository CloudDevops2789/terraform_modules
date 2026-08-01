##################################################################################################
# Remote Access
##################################################################################################

############################################
# Client VPN
############################################
# Provides administrator remote access into the Recovery Access VPC,
# the designated entry point for the IRE. Authorization is currently
# all-groups via certificate auth; the commented block below documents
# the planned extension point for group-scoped access once IAM Identity
# Center (SAML) is introduced as the auth source - at that point the
# interface here barely changes, it just gains an optional group
# identifier per authorization rule.add
module "client_vpn" {

  source = "../../modules/client-vpn"

  name = local.client_vpn.name

  #server_certificate_arn     = "arn:aws:acm:us-east-1:781436988948:certificate/5bf9218b-6fbc-4cb3-a02b-0eb291d771b5"
  #root_certificate_chain_arn = "arn:aws:acm:us-east-1:781436988948:certificate/fc51c80f-aa8a-4830-ad23-5a3f42ffd26f"
  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn

  client_cidr_block = local.client_vpn.client_cidr_block

  vpc_id = module.recovery_access.vpc_id

  network_associations = {

    az1 = {
      subnet_id = module.recovery_access.private_subnet_ids[0]
    }

    az2 = {
      subnet_id = module.recovery_access.private_subnet_ids[1]
    }

  }

  security_group_ids = [
    module.security_group.security_group_ids["management"]
  ]

  split_tunnel       = local.client_vpn.split_tunnel
  transport_protocol = local.client_vpn.transport_protocol
  vpn_port           = local.client_vpn.vpn_port
  dns_servers        = local.client_vpn.dns_servers

  session_timeout_hours = local.client_vpn.session_timeout_hours

  authorization_rules = {
    #When we  move to IAM Identity Center (SAML), your interface barely changes.
    #you could extend the object with an optional group identifier
    #access_group_id = "cloud-admin"
    recovery_access = {

      target_network_cidr = module.recovery_access.vpc_cidr

      authorize_all_groups = local.client_vpn.authorize_all_groups

    }

  }

  routes = {}

}