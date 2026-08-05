# Map comprehension building per-key-pair tags, identical in shape to the
# ec2 and security-group modules. merge() applies defaults first, then
# caller overrides, then an authoritative Name.
locals {

  tags = {
    for key_name, key in var.key_pairs :
    key_name => merge(
      var.tags,
      key.tags,
      {
        Name = key_name
      }
    )
  }

}
