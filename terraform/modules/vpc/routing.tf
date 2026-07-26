

# CONDITIONAL RESOURCE: `count = condition ? 1 : 0` is the idiom for
# creating a resource only sometimes. If the caller passes no public
# subnets, has_public_subnets is false, count is 0, and no IGW exists -
# which is exactly what the IRE design wants for the isolated VPCs.
# A counted resource is a LIST, so later references need an index: this[0].
resource "aws_internet_gateway" "this" {

  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

# Route table for the public tier - also conditional, created only
# alongside the IGW.
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

# The default route ("catch-all" 0.0.0.0/0) pointing at the IGW is what
# actually makes the public route table public. Defined as a separate
# aws_route resource rather than an inline route block so it can carry its
# own count condition.
resource "aws_route" "public_default" {

  count = local.has_public_subnets ? 1 : 0

  route_table_id = aws_route_table.public[0].id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.this[0].id
}

# Associations bind subnets to a route table. for_each iterates directly
# over the aws_subnet.public RESOURCE (itself a map because it used
# for_each), so each subnet gets an association keyed by the same name.
resource "aws_route_table_association" "public" {

  for_each = aws_subnet.public

  subnet_id = each.value.id

  route_table_id = aws_route_table.public[0].id

}


# Single shared route table for all private subnets (no count - it always
# exists). It has no 0.0.0.0/0 route at all, so private subnets have no
# internet path. Routes toward the Transit Gateway get added here later
# when inter-VPC traffic is enabled.
resource "aws_route_table" "private" {

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-rt"
    }
  )
}

# Add routes to remote networks through the Transit Gateway. for_each
# converts the input list into a map keyed by destination CIDR, giving each
# route a stable Terraform resource address and avoiding index-based
# references.
resource "aws_route" "public_transit_gateway" {
  for_each = local.has_public_subnets ? {
    for route in var.public_transit_gateway_routes :
    route.destination_cidr_block => route
  } : {}

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = each.value.destination_cidr_block
  transit_gateway_id     = each.value.transit_gateway_id
}

resource "aws_route" "private_transit_gateway" {
  for_each = {
    for route in var.private_transit_gateway_routes :
    route.destination_cidr_block => route
  }

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = each.value.destination_cidr_block
  transit_gateway_id     = each.value.transit_gateway_id
}
resource "aws_route_table_association" "private" {

  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = aws_route_table.private.id

}
