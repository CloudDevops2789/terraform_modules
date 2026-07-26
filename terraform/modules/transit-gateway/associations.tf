# Associate each VPC attachment with its Transit Gateway route table.
# The attachment specifies the routing domain using the `route_table`
# attribute defined in `var.vpc_attachments`.
# ASSOCIATION answers: which route table does this attachment consult when
# sending traffic INTO the Transit Gateway? Each attachment associates with
# exactly one route table, so this for_each runs once per attachment.
#
# The nested lookup chain is what creates the dependency graph: referencing
# aws_ec2_transit_gateway_route_table.this[...] tells Terraform the route
# table must exist first, with no explicit depends_on needed.
resource "aws_ec2_transit_gateway_route_table_association" "this" {

  for_each = var.vpc_attachments

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table].id
}