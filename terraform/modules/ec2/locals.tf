# LOCALS are named values computed once and reused inside the module.
#
# This is a MAP COMPREHENSION: `for k, v in map : k => expr` transforms
# one map into another with the same keys. It builds the final tag set
# for every instance up front, so ec2.tf stays a simple lookup.
#
# merge() combines maps left to right and later keys win, giving a clear
# precedence order: module-wide defaults, then per-instance overrides,
# then a Name derived from the map key (always authoritative).
locals {

  tags = {
    for instance_name, instance in var.instances :
    instance_name => merge(
      var.tags,
      instance.tags,
      {
        Name = instance_name
      }
    )
  }

}
