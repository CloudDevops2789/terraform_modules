##################################################################################################
# VPC Module Outputs
##################################################################################################
#
# Outputs are the values that consuming environments use after this module
# creates the VPC, subnets, route tables, and optional Internet Gateway.
#
# Resources remain keyed by the caller-defined map keys. This is easier to
# understand and safer than relying on list positions such as subnet_ids[0].

##################################################################################################
# VPC
##################################################################################################

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "Primary IPv4 CIDR block assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

##################################################################################################
# Subnets
##################################################################################################
#
# The complete subnets output is useful when a consumer needs more than only
# the subnet ID.
#
# Example:
#
# module.vpc.subnets["firewall-a"].id
# module.vpc.subnets["firewall-a"].availability_zone
# module.vpc.subnets["firewall-a"].route_table_id

output "subnets" {
  description = "Subnet details keyed by the caller-defined subnet key."

  value = {
    for key, subnet in aws_subnet.this : key => {
      id   = subnet.id
      arn  = subnet.arn
      name = local.subnets[key].name

      cidr_block = subnet.cidr_block

      availability_zone    = subnet.availability_zone
      availability_zone_id = subnet.availability_zone_id

      group = local.subnets[key].group

      route_table_key = local.subnets[key].route_table_key

      route_table_id = aws_route_table.this[
        local.subnets[key].route_table_key
      ].id

      map_public_ip_on_launch = subnet.map_public_ip_on_launch
    }
  }
}

##################################################################################################
# Subnet ID lookups
##################################################################################################
#
# Use subnet_ids when one specific subnet is required:
#
# module.vpc.subnet_ids["application-a"]
#
# Use subnet_ids_by_group when a service needs every subnet belonging to one
# logical role:
#
# module.vpc.subnet_ids_by_group["transit-gateway"]
#
# Each group returns a list because multiple subnets may belong to the same
# group and the same Availability Zone.

output "subnet_ids" {
  description = "Subnet IDs keyed by the caller-defined subnet key."

  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
  }
}

output "subnet_ids_by_group" {
  description = "Subnet IDs grouped by the caller-defined subnet group."

  value = {
    for group in local.subnet_groups :
    group => [
      for key in sort(keys(local.subnets)) :
      aws_subnet.this[key].id
      if local.subnets[key].group == group
    ]
  }
}

##################################################################################################
# Route tables
##################################################################################################
#
# The environment or routing module uses these outputs to add routes toward
# Network Firewall endpoints, Transit Gateway, NAT Gateway, Internet Gateway,
# VPC peering, or another supported route target.

output "route_tables" {
  description = "Route-table details keyed by the caller-defined route-table key."

  value = {
    for key, route_table in aws_route_table.this : key => {
      id    = route_table.id
      arn   = route_table.arn
      name  = local.route_tables[key].name
      group = local.route_tables[key].group
    }
  }
}

output "route_table_ids" {
  description = "Route-table IDs keyed by the caller-defined route-table key."

  value = {
    for key, route_table in aws_route_table.this :
    key => route_table.id
  }
}

output "route_table_ids_by_group" {
  description = "Route-table IDs grouped by the caller-defined route-table group."

  value = {
    for group in local.route_table_groups :
    group => [
      for key in sort(keys(local.route_tables)) :
      aws_route_table.this[key].id
      if local.route_tables[key].group == group
    ]
  }
}

##################################################################################################
# Internet Gateway
##################################################################################################
#
# This output is null when create_internet_gateway is false.
#
# A consuming environment may later use the ID for controlled Island Browser,
# NAT Gateway, Network Firewall-inspected egress, or approved ingress routing.

output "internet_gateway_id" {
  description = "Internet Gateway ID, or null when no Internet Gateway was created."
  value       = try(aws_internet_gateway.this[0].id, null)
}