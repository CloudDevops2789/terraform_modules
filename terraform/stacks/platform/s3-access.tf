##################################################################################################
# Amazon S3 Private Access
#
# S3 Gateway endpoints provide private VPC-local access to Amazon S3 without
# requiring NAT Gateway or public Internet routing.
#
# Route-table placement is driven by logical Platform route-table groups rather
# than hardcoded route-table IDs.
##################################################################################################

module "s3_gateway_endpoints" {
  for_each = var.s3_gateway_endpoint_bindings

  source = "../../modules/vpc-endpoints"

  vpc_id = module.vpc[each.key].vpc_id

  gateway_endpoints = {
    s3 = {
      name = coalesce(
        each.value.name,
        "${local.name_prefix}-${replace(each.key, "_", "-")}-s3"
      )

      service_name = "com.amazonaws.${var.aws_region}.s3"

      route_table_ids = toset(flatten([
        for route_table_group in sort(
          tolist(each.value.route_table_groups)
        ) :
        module.vpc[
          each.key
        ].route_table_ids_by_group[route_table_group]
      ]))

      policy = each.value.policy
    }
  }

  tags = merge(
    local.org_tags,
    {
      org_service_name = "s3-private-access"
    }
  )
}
