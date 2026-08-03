##################################################################################################
# Firewall Outputs
##################################################################################################
# Endpoint maps are designed for direct use by route-table modules. Consumers should route each
# Availability Zone through the endpoint deployed in that same Availability Zone.
output "firewalls" {
  description = "Network Firewall attributes keyed by the caller's logical identifiers."
  value = {
    for key, firewall in aws_networkfirewall_firewall.this : key => {
      arn                              = firewall.arn
      id                               = firewall.id
      name                             = firewall.name
      firewall_policy_arn              = firewall.firewall_policy_arn
      vpc_id                           = firewall.vpc_id
      transit_gateway_id               = firewall.transit_gateway_id
      transit_gateway_owner_account_id = firewall.transit_gateway_owner_account_id
      update_token                     = firewall.update_token
      firewall_status                  = firewall.firewall_status
      endpoint_ids_by_availability_zone = {
        for sync_state in try(firewall.firewall_status[0].sync_states, []) :
        sync_state.availability_zone => sync_state.attachment[0].endpoint_id
        if try(sync_state.attachment[0].endpoint_id, null) != null
      }
      endpoint_ids_by_subnet_id = {
        for sync_state in try(firewall.firewall_status[0].sync_states, []) :
        sync_state.attachment[0].subnet_id => sync_state.attachment[0].endpoint_id
        if try(sync_state.attachment[0].endpoint_id, null) != null
      }
      transit_gateway_attachment_ids = [
        for sync_state in try(firewall.firewall_status[0].transit_gateway_attachment_sync_states, []) :
        sync_state.attachment_id
        if try(sync_state.attachment_id, null) != null
      ]
    }
  }
}
output "firewall_arns" {
  description = "Network Firewall ARNs keyed by logical identifiers."
  value = {
    for key, firewall in aws_networkfirewall_firewall.this : key => firewall.arn
  }
}
output "endpoint_ids_by_availability_zone" {
  description = "Primary firewall endpoint IDs keyed first by firewall logical key and then Availability Zone."
  value = {
    for key, firewall in aws_networkfirewall_firewall.this : key => {
      for sync_state in try(firewall.firewall_status[0].sync_states, []) :
      sync_state.availability_zone => sync_state.attachment[0].endpoint_id
      if try(sync_state.attachment[0].endpoint_id, null) != null
    }
  }
}
output "endpoint_ids_by_subnet_id" {
  description = "Primary firewall endpoint IDs keyed first by firewall logical key and then firewall subnet ID."
  value = {
    for key, firewall in aws_networkfirewall_firewall.this : key => {
      for sync_state in try(firewall.firewall_status[0].sync_states, []) :
      sync_state.attachment[0].subnet_id => sync_state.attachment[0].endpoint_id
      if try(sync_state.attachment[0].endpoint_id, null) != null
    }
  }
}
##################################################################################################
# VPC Endpoint Association Outputs
##################################################################################################
output "vpc_endpoint_associations" {
  description = "Additional VPC endpoint association attributes keyed by logical identifiers."
  value = {
    for key, association in aws_networkfirewall_vpc_endpoint_association.this : key => {
      arn                             = association.vpc_endpoint_association_arn
      id                              = association.vpc_endpoint_association_id
      firewall_arn                    = association.firewall_arn
      vpc_id                          = association.vpc_id
      vpc_endpoint_association_status = association.vpc_endpoint_association_status
      endpoint_ids_by_availability_zone = {
        for sync_state in try(association.vpc_endpoint_association_status[0].association_sync_state, []) :
        sync_state.availability_zone => sync_state.attachment[0].endpoint_id
        if try(sync_state.attachment[0].endpoint_id, null) != null
      }
      endpoint_ids_by_subnet_id = {
        for sync_state in try(association.vpc_endpoint_association_status[0].association_sync_state, []) :
        sync_state.attachment[0].subnet_id => sync_state.attachment[0].endpoint_id
        if try(sync_state.attachment[0].endpoint_id, null) != null
      }
    }
  }
}
output "vpc_endpoint_association_arns" {
  description = "Additional VPC endpoint association ARNs keyed by logical identifiers."
  value = {
    for key, association in aws_networkfirewall_vpc_endpoint_association.this :
    key => association.vpc_endpoint_association_arn
  }
}
