##################################################################################################
# VPC Test Outputs
##################################################################################################
#
# These outputs make it easy to verify the topology after apply.
#
# The complete subnet output includes Availability Zone and route-table
# information. Grouped outputs demonstrate that consumers can select subnet
# collections without depending on list positions.

output "vpc_id" {
  description = "ID of the VPC created by the module under test."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC created by the module under test."
  value       = module.vpc.vpc_cidr
}

output "subnets" {
  description = "Complete subnet details keyed by the test subnet key."
  value       = module.vpc.subnets
}

output "subnet_ids" {
  description = "Subnet IDs keyed by the test subnet key."
  value       = module.vpc.subnet_ids
}

output "subnet_ids_by_group" {
  description = "Subnet IDs grouped by application or firewall role."
  value       = module.vpc.subnet_ids_by_group
}

output "route_table_ids" {
  description = "Route-table IDs keyed by the test route-table key."
  value       = module.vpc.route_table_ids
}

output "route_table_ids_by_group" {
  description = "Route-table IDs grouped by application or firewall role."
  value       = module.vpc.route_table_ids_by_group
}

output "internet_gateway_id" {
  description = "Internet Gateway ID created by this module test. No routes are created automatically."
  value       = module.vpc.internet_gateway_id
}
