##################################################################################################
# Centralized AWS Network Firewall
##################################################################################################

module "network_firewall" {
  source = "../../modules/network-firewall"

  firewalls = (
    local.network_firewall_enabled
    ? {
      inspection = {
        name = local.resource_names.network_firewall

        description = "Centralized inspection firewall for the AWS ${var.naming.project_display_name} ${var.naming.environment_display_name}."

        firewall_policy_arn = (
          module.network_firewall_policy
          .firewall_policy_arns["centralized_inspection"]
        )

        vpc_id = module.vpc[
          local.inspection_vpc_key
        ].vpc_id

        subnet_mappings = {
          for subnet_key, subnet in module.vpc[
            local.inspection_vpc_key
          ].subnets :
          subnet_key => {
            subnet_id       = subnet.id
            ip_address_type = "IPV4"
          }
          if(
            subnet.group ==
            local.inspection_firewall_subnet_group
          )
        }

        enabled_analysis_types = [
          "HTTP_HOST",
          "TLS_SNI"
        ]

        delete_protection                 = false
        firewall_policy_change_protection = false
        subnet_change_protection          = false

        tags = {
          org_service_name = "centralized-network-inspection"
        }
      }
    }
    : {}
  )

  tags = local.org_tags
}

output "network_firewall_arn" {
  description = "ARN of the centralized Network Firewall, or null when inspection is bypassed."

  value = try(
    module.network_firewall.firewall_arns["inspection"],
    null
  )
}

output "network_firewall_endpoint_ids_by_availability_zone" {
  description = "Firewall endpoint IDs keyed by Availability Zone."

  value = try(
    module.network_firewall
    .endpoint_ids_by_availability_zone["inspection"],
    {}
  )
}
