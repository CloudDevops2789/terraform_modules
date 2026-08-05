# Per-group tag maps, same comprehension + merge() precedence used by the
# ec2 and key-pair modules.
locals {

  tags = {
    for sg_name, sg in var.security_groups :
    sg_name => merge(
      var.tags,
      sg.tags,
      {
        Name = sg_name
      }
    )
  }

}
