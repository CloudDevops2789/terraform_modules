output "transit_gateway_id" {
  description = "ID of the Transit Gateway created by the module under test."
  value       = module.transit_gateway.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway created by the module under test."
  value       = module.transit_gateway.arn
}

output "route_table_ids" {
  description = "Transit Gateway Route Table IDs created by the module under test."
  value       = module.transit_gateway.route_table_ids
}
