##################################################################################################
# Gateway VPC Endpoints
##################################################################################################

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.gateway_endpoints

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"

  route_table_ids = sort(tolist(each.value.route_table_ids))
  policy          = each.value.policy

  tags = merge(
    var.tags,
    each.value.tags,
    each.value.name == null ? {} : {
      Name = each.value.name
    }
  )
}
