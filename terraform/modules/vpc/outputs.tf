# OUTPUTS are the module's public return values - the only way callers
# (like sandbox/main.tf) can read what the module created. Everything not
# output is private to the module.
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.this.cidr_block
}

############################################
# Public Subnets
############################################

# values(map) turns the resource map into a list; the [*] SPLAT then
# collects the .id of every element - a flat list of subnet IDs, which is
# the shape the TGW attachment input expects.
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = values(aws_subnet.public)[*].id
}

# FOR EXPRESSION (comprehension) building a map of subnet-key -> subnet-id,
# useful when a caller needs a specific subnet by name rather than a list.
output "public_subnet_map" {
  description = "Public subnet map"

  value = {
    for k, subnet in aws_subnet.public :
    k => subnet.id
  }
}

############################################
# Private Subnets
############################################

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = values(aws_subnet.private)[*].id
}

output "private_subnet_map" {
  description = "Private subnet map"

  value = {
    for k, subnet in aws_subnet.private :
    k => subnet.id
  }
}

############################################
# Route Tables
############################################

# try() returns the first argument that doesn't error. Because the public
# route table is conditional (count), this[0] may not exist; try() converts
# that error into null instead of breaking `terraform output`.
output "public_route_table_id" {
  value = try(aws_route_table.public[0].id, null)
}

# Legacy compatibility output. Advanced topology may contain several private
# route tables, so this returns null when the module uses advanced mode.
output "private_route_table_id" {
  description = "Legacy shared private route table ID, or null in advanced topology mode."
  value       = try(aws_route_table.legacy_private["legacy"].id, null)
}

############################################
# Internet Gateway
############################################

output "internet_gateway_id" {
  value = try(aws_internet_gateway.this[0].id, null)
}
