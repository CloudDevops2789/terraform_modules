module "remote_access_security_group" {
  source = "../../modules/security-group"

  security_groups = var.remote_access_enabled ? {
    endpoint = {
      name        = "${var.name}-endpoint"
      description = "AWS Client VPN endpoint network policy"
      vpc_id      = local.association_vpc_id
    }
  } : {}

  tags = local.tags
}

module "remote_access_security_group_rules" {
  source = "../../modules/security-group-rule"

  rules = var.remote_access_enabled ? merge(
    local.endpoint_egress_security_group_rules,
    local.target_ingress_security_group_rules
  ) : {}
}

module "client_vpn" {
  count  = var.remote_access_enabled ? 1 : 0
  source = "../../modules/client-vpn"

  name                = var.name
  authentication_type = var.authentication_type
  active_directory_id = try(var.identity_contract.directory_id, null)

  server_certificate_arn = var.server_certificate_arn
  root_certificate_chain_arn = (
    var.authentication_type == "directory_and_mutual"
    ? var.client_root_certificate_chain_arn
    : null
  )

  client_cidr_block = var.client_cidr_block
  vpc_id            = local.association_vpc_id

  network_associations = {
    for index, subnet_id in local.association_subnet_ids :
    tostring(index) => { subnet_id = subnet_id }
  }

  security_group_ids = [
    module.remote_access_security_group.security_group_ids["endpoint"]
  ]

  dns_servers               = local.dns_servers
  split_tunnel              = var.split_tunnel
  transport_protocol        = var.transport_protocol
  vpn_port                  = var.vpn_port
  session_timeout_hours     = var.session_timeout_hours
  enable_connection_logging = var.enable_connection_logging
  log_retention_in_days     = var.log_retention_in_days

  authorization_rules = local.authorization_rules
  routes              = local.routes

  tags = local.tags

  depends_on = [module.remote_access_security_group_rules]
}
