# Propagate VPC attachment routes into the configured Transit Gateway
# route tables. Each propagation creates one learned route source.
# PROPAGATION is the mirror of association: it answers which route tables
# LEARN this attachment's VPC CIDR. Association controls where traffic
# looks up routes; propagation controls who can see you. Together they
# define the reachability matrix.
#
# One attachment can propagate into many route tables, so this cannot be a
# simple for_each over the attachments map. The expression below is the
# standard Terraform idiom for flattening a one-to-many relationship:
#   - the inner `for` loops over each attachment's propagate_to list,
#     producing one object per (attachment, route table) pair;
#   - flatten() collapses the resulting list-of-lists into a flat list;
#   - the outer `for` re-keys that list into a map, because for_each
#     requires a map or set - the composite key "attachment-routetable"
#     keeps every resource address stable and unique.
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {

  for_each = {
    for propagation in flatten([
      for attachment_key, attachment in var.vpc_attachments : [
        for route_table_key in attachment.propagate_to : {
          key             = "${attachment_key}-${route_table_key}"
          attachment_key  = attachment_key
          route_table_key = route_table_key
        }
      ]
    ]) : propagation.key => propagation
  }

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_key].id

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_key].id
}