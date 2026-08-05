##################################################################################################
# Module Under Test: Network Firewall TLS Inspection
##################################################################################################
module "network_firewall_tls_inspection" {
  source                        = "../../../modules/network-firewall-tls-inspection"
  tls_inspection_configurations = local.tls_inspection_configurations
  tags                          = local.org_tags
}
