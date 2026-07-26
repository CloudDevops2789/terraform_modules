resource "aws_key_pair" "this" {
  for_each = var.key_pairs

  key_name   = each.key
  public_key = each.value.public_key

  tags = local.tags[each.key]
}