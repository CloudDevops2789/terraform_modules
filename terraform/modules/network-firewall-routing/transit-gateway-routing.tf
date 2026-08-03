##################################################################################################
# Transit Gateway Static Routes
##################################################################################################
resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = local.transit_gateway_routes
  blackhole                      = each.value.blackhole
  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.transit_gateway_route_table_id
}
##################################################################################################
# Transit Gateway Route Table Associations
##################################################################################################
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = local.transit_gateway_route_table_associations
  replace_existing_association   = each.value.replace_existing_association
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.transit_gateway_route_table_id
}
##################################################################################################
# Transit Gateway Route Table Propagations
##################################################################################################
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = local.transit_gateway_route_table_propagations
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.transit_gateway_route_table_id
}
