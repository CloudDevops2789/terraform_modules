##################################################################################################
# Route Tables
##################################################################################################
#
# One route table is created for every entry in var.route_tables.
#
# The module creates route tables and associates subnets with them. It does
# not decide where traffic should go.
#
# Routes toward Network Firewall endpoints, Transit Gateway, NAT Gateway,
# Internet Gateway, VPC peering, or other targets are created by the consuming
# environment or a dedicated routing module.

resource "aws_route_table" "this" {
  for_each = local.route_tables

  vpc_id = aws_vpc.this.id

  tags = each.value.tags
}

##################################################################################################
# Subnet-to-route-table associations
##################################################################################################
#
# Every subnet explicitly references one route-table key.
#
# Several subnets may reference the same route table. Alternatively, the
# caller may create one route table for every subnet or every Availability
# Zone.

resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this

  subnet_id = each.value.id

  route_table_id = aws_route_table.this[
    local.subnets[each.key].route_table_key
  ].id
}
