##################################################################################################
# Validation Outputs
##################################################################################################
output "vpc_routes" {
  description = "VPC routes created by the routing module test."
  value       = module.network_firewall_routing.vpc_routes
}
output "route_table_associations" {
  description = "Route table associations created by the routing module test."
  value       = module.network_firewall_routing.route_table_associations
}
output "transit_gateway_routes" {
  description = "Transit Gateway routes created by the routing module test."
  value       = module.network_firewall_routing.transit_gateway_routes
}
output "firewall_endpoint_ids" {
  description = "Network Firewall endpoint IDs used as route targets."
  value       = module.network_firewall.endpoint_ids_by_availability_zone
}
