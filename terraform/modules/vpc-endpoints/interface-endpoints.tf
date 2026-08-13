##################################################################################################
# Interface VPC Endpoints
##################################################################################################

resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Interface"

  subnet_ids          = sort(tolist(each.value.subnet_ids))
  security_group_ids  = sort(tolist(each.value.security_group_ids))
  private_dns_enabled = each.value.private_dns_enabled
  policy              = each.value.policy

  tags = merge(
    var.tags,
    each.value.tags,
    each.value.name == null ? {} : {
      Name = each.value.name
    }
  )
}
