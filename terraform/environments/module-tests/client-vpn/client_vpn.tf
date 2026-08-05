##################################################################################################
# Module Under Test: client-vpn
##################################################################################################
# terraform/modules/client-vpn is the module this environment exists to
# validate: the endpoint, its CloudWatch logging (created inside the
# module itself), one network association, and one authorization rule.
module "client_vpn" {

  source = "../../../modules/client-vpn"

  name = local.client_vpn.name

  # Either the ARNs an operator supplied via var.server_certificate_arn /
  # var.root_certificate_chain_arn, or the throwaway ones generated in
  # certificates.tf - see local.generate_certificates in locals.tf.
  server_certificate_arn     = local.effective_server_certificate_arn
  root_certificate_chain_arn = local.effective_root_certificate_chain_arn

  client_cidr_block = local.client_vpn.client_cidr_block

  vpc_id = module.vpc.vpc_id

  network_associations = {
    az1 = {
      subnet_id = module.vpc.private_subnet_map["private-a"]
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
      authorize_all_groups = local.client_vpn.authorize_all_groups
    }
  }

  tags = local.org_tags
}
