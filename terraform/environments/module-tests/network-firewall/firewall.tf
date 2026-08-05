##################################################################################################
# Module Under Test: Network Firewall
##################################################################################################
# The firewall policy ARN is resolved by the root module from the policy module's logical output key.
module "network_firewall" {
  source = "../../../modules/network-firewall"
  firewalls = {
    inspection = {
      name                                = "module-test-network-firewall"
      description                         = "Validates a two-AZ VPC-attached AWS Network Firewall."
      firewall_policy_arn                 = module.network_firewall_policy.firewall_policy_arns["inspection"]
      vpc_id                              = aws_vpc.this.id
      availability_zone_change_protection = false
      delete_protection                   = false
      firewall_policy_change_protection   = false
      subnet_change_protection            = false
      enabled_analysis_types = [
        "HTTP_HOST",
        "TLS_SNI"
      ]
      subnet_mappings = {
        for availability_zone, subnet in aws_subnet.firewall :
        availability_zone => {
          subnet_id       = subnet.id
          ip_address_type = "IPV4"
        }
      }
      timeouts = {
        create = "60m"
        update = "60m"
        delete = "60m"
      }
    }
  }
  tags = local.org_tags
}
