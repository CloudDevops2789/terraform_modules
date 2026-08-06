##################################################################################################
# Centralized AWS Network Firewall
##################################################################################################
# One endpoint is deployed in each dedicated firewall subnet. No routes point at these endpoints
# yet, so this commit does not alter any current Sandbox traffic path.

module "network_firewall" {
  source = "../../modules/network-firewall"

  firewalls = {
    inspection = {
      name        = "ire-sandbox-centralized-inspection"
      description = "Two-AZ centralized inspection firewall for the AWS IRE Sandbox."

      firewall_policy_arn = (
        module.network_firewall_policy
        .firewall_policy_arns["centralized_inspection"]
      )

      vpc_id = module.inspection_vpc.vpc_id

      subnet_mappings = {
        for subnet_key, subnet in module.inspection_vpc.subnets :
        subnet_key => {
          subnet_id       = subnet.id
          ip_address_type = "IPV4"
        }
        if subnet.group == "network-firewall"
      }

      enabled_analysis_types = [
        "HTTP_HOST",
        "TLS_SNI"
      ]

      # Sandbox lifecycle settings remain disabled to support clean teardown.
      # Production should evaluate enabling all applicable protections.
      delete_protection                 = false
      firewall_policy_change_protection = false
      subnet_change_protection          = false

      tags = {
        org_service_name = "centralized-network-inspection"
      }
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Firewall Integration Outputs
##################################################################################################

output "network_firewall_arn" {
  description = "ARN of the centralized Sandbox Network Firewall."
  value       = module.network_firewall.firewall_arns["inspection"]
}

output "network_firewall_endpoint_ids_by_availability_zone" {
  description = "Firewall endpoint IDs keyed by Availability Zone for future same-AZ routing."
  value = (
    module.network_firewall
    .endpoint_ids_by_availability_zone["inspection"]
  )
}
