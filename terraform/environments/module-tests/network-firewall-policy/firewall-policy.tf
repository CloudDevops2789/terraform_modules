##################################################################################################
# Module Under Test: Network Firewall Policy
##################################################################################################
module "network_firewall_policy" {
  source            = "../../../modules/network-firewall-policy"
  firewall_policies = local.firewall_policies
  tags              = local.org_tags
}
