##################################################################################################
# Supporting Network Firewall
##################################################################################################
module "network_firewall" {
  source = "../../../modules/network-firewall"
  firewalls = {
    inspection = {
      name                = "module-test-network-firewall-logging"
      description         = "Supporting firewall for logging configuration validation."
      firewall_policy_arn = module.network_firewall_policy.firewall_policy_arns["inspection"]
      vpc_id              = aws_vpc.this.id
      subnet_mappings = {
        primary = {
          subnet_id       = aws_subnet.firewall.id
          ip_address_type = "IPV4"
        }
      }
      delete_protection                 = false
      firewall_policy_change_protection = false
      subnet_change_protection          = false
    }
  }
  tags = local.org_tags
}
