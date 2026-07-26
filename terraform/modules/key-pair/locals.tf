locals {

  tags = {
    for key_name, key in var.key_pairs :
    key_name => merge(
      var.default_tags,
      key.tags,
      {
        Name = key_name
      }
    )
  }

}