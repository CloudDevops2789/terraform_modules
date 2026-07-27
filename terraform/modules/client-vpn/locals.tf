locals {
  default_tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}