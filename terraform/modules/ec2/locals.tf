locals {

  tags = {
    for instance_name, instance in var.instances :
    instance_name => merge(
      var.default_tags,
      instance.tags,
      {
        Name = instance_name
      }
    )
  }

}