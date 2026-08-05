##################################################################################################
# Internet Gateway
##################################################################################################
#
# Legacy mode creates an Internet Gateway automatically when public subnets
# exist.
#
# Advanced mode creates one only when create_internet_gateway is explicitly
# enabled. Advanced mode intentionally does not infer or create default routes.

resource "aws_internet_gateway" "this" {

  count = local.internet_gateway_enabled ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

##################################################################################################
# Legacy public routing
##################################################################################################
#
# These resources preserve the original public_subnets behaviour and resource
# addresses. They are not created in advanced mode.

resource "aws_route_table" "public" {

  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

# A subnet becomes publicly routed only when its route table contains a
# default route to an Internet Gateway.
resource "aws_route" "public_default" {

  count = local.has_public_subnets ? 1 : 0

  route_table_id = aws_route_table.public[0].id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {

  for_each = aws_subnet.public

  subnet_id = each.value.id

  route_table_id = aws_route_table.public[0].id
}

# Legacy public routes remain limited to Transit Gateway targets. Advanced
# topology exposes route-table IDs so arbitrary routes can be managed by an
# environment or a dedicated routing module.
resource "aws_route" "public_transit_gateway" {

  for_each = local.has_public_subnets ? {
    for route in var.public_transit_gateway_routes :
    route.destination_cidr_block => route
  } : {}

  route_table_id = aws_route_table.public[0].id

  destination_cidr_block = each.value.destination_cidr_block

  transit_gateway_id = each.value.transit_gateway_id
}

##################################################################################################
# Legacy private routing
##################################################################################################
#
# Existing consumers continue to receive one shared private route table.
#
# The stable "legacy" key allows the resource to be created conditionally
# without using a positional count index. moved.tf migrates existing state
# from the previous unkeyed aws_route_table.private address.

resource "aws_route_table" "legacy_private" {

  for_each = local.legacy_mode ? {
    legacy = true
  } : {}

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-rt"
    }
  )
}

resource "aws_route" "private_transit_gateway" {

  # Advanced topology does not consume these legacy routes. It exposes route
  # table IDs so the environment can create routes toward Network Firewall
  # endpoints, Transit Gateway, NAT Gateways, or other supported targets.
  for_each = local.legacy_mode ? {
    for route in var.private_transit_gateway_routes :
    route.destination_cidr_block => route
  } : {}

  route_table_id = aws_route_table.legacy_private["legacy"].id

  destination_cidr_block = each.value.destination_cidr_block

  transit_gateway_id = each.value.transit_gateway_id
}

resource "aws_route_table_association" "private" {

  # aws_subnet.private is empty in advanced mode, so these associations exist
  # only for legacy private subnets.
  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = aws_route_table.legacy_private["legacy"].id
}
