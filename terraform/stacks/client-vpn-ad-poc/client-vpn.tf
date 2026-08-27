module "client_vpn" {
  count = var.client_vpn_enabled ? 1 : 0

  source = "../../modules/client-vpn"

  name                = local.name_prefix
  authentication_type = var.authentication_type
  active_directory_id = module.managed_microsoft_ad.directory_id

  server_certificate_arn = var.server_certificate_arn
  root_certificate_chain_arn = (
    var.authentication_type == "directory_and_mutual"
    ? var.root_certificate_chain_arn
    : null
  )

  client_cidr_block = var.client_cidr_block
  vpc_id            = module.vpc.vpc_id

  network_associations = {
    primary = {
      subnet_id = module.vpc.subnet_ids["directory-a"]
    }
  }

  security_group_ids = [
    module.security_group.security_group_ids["client-vpn"]
  ]

  dns_servers          = module.managed_microsoft_ad.dns_ip_addresses
  split_tunnel         = true
  transport_protocol   = "udp"
  vpn_port             = 443
  session_timeout_hours = 8

  authorization_rules = {
    poc-vpc = {
      target_network_cidr  = var.vpc_cidr_block
      authorize_all_groups = var.client_vpn_access_group_id == null
      access_group_id       = var.client_vpn_access_group_id
    }
  }

  routes = {}

  tags = local.tags
}
