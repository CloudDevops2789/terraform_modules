##################################################################################################
# Module Under Test: client-vpn
##################################################################################################
# terraform/modules/client-vpn is the module this environment exists to
# validate: the endpoint, its CloudWatch logging (created inside the
# module itself), one network association, and one authorization rule.
module "client_vpn" {

  source = "../../../modules/client-vpn"

  name = local.client_vpn.name

  # The test validates one supported authentication path at a time. The
  # authentication_type variable controls which path is tested.
  authentication_type = var.authentication_type
  active_directory_id = var.active_directory_id

  server_certificate_arn = var.server_certificate_arn

  root_certificate_chain_arn = (
    contains(["certificate", "directory_and_mutual"], var.authentication_type)
    ? var.root_certificate_chain_arn
    : null
  )

  saml_provider_arn = (
    var.authentication_type == "federated"
    ? var.saml_provider_arn
    : null
  )

  client_cidr_block = local.client_vpn.client_cidr_block

  vpc_id = module.vpc.vpc_id

  network_associations = {
    az1 = {
      subnet_id = module.vpc.subnet_ids["private-a"]
    }
  }

  security_group_ids = [
    module.security_group.security_group_ids["vpn"]
  ]

  split_tunnel       = local.client_vpn.split_tunnel
  transport_protocol = local.client_vpn.transport_protocol
  vpn_port           = local.client_vpn.vpn_port
  dns_servers        = local.client_vpn.dns_servers

  session_timeout_hours = local.client_vpn.session_timeout_hours

  # One authorization rule proving authenticated clients can be granted
  # access to the supporting VPC's CIDR. Routes are intentionally omitted -
  # they are not required for the endpoint itself to deploy successfully.
  authorization_rules = {
    vpc = {
      target_network_cidr  = module.vpc.vpc_cidr
      authorize_all_groups = var.access_group_id == null
      access_group_id      = var.access_group_id
    }
  }

  tags = local.org_tags
}
