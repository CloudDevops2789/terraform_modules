##################################################################################################
# Supporting Network Firewall Policy
##################################################################################################
# Associating the TLS inspection ARN proves that the configuration can be consumed by the existing
# policy module and increments the configuration's association count.
module "network_firewall_policy" {
  source            = "../../../modules/network-firewall-policy"
  firewall_policies = local.firewall_policies
  tags              = local.org_tags
}
