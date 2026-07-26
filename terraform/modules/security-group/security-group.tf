resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.key
  description = each.value.description
  vpc_id      = each.value.vpc_id

  tags = local.tags[each.key]
}