##################################################################################################
# Validation Outputs
##################################################################################################
output "firewalls" {
  description = "Firewall attributes created by the module test."
  value       = module.network_firewall.firewalls
}
output "endpoint_ids_by_availability_zone" {
  description = "Firewall endpoint IDs for same-AZ route-table integration."
  value       = module.network_firewall.endpoint_ids_by_availability_zone
}
output "endpoint_ids_by_subnet_id" {
  description = "Firewall endpoint IDs keyed by dedicated firewall subnet ID."
  value       = module.network_firewall.endpoint_ids_by_subnet_id
}
output "firewall_policy_arns" {
  description = "Supporting firewall policy ARN used by the firewall."
  value       = module.network_firewall_policy.firewall_policy_arns
}
