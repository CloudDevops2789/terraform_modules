############################################
# Client VPN Authorization Rules
############################################

# Authorization rules determine which destination networks
# authenticated VPN clients are permitted to access.
#
# Unlike routes, authorization rules are security controls.
#
# One rule is created for each entry supplied by the root module.
#
resource "aws_ec2_client_vpn_authorization_rule" "this" {

  for_each = var.authorization_rules

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

  target_network_cidr = each.value.target_network_cidr

  authorize_all_groups = each.value.authorize_all_groups
  access_group_id      = each.value.authorize_all_groups ? null : each.value.access_group_id

  timeouts {
    create = "20m"
    delete = "20m"
  }
}
