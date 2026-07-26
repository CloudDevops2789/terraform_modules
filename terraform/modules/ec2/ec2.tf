# FOR_EACH over a map: one EC2 instance per entry of var.instances.
# each.key is the logical name ("management"), each.value the object
# describing it. Because for_each addresses resources by KEY rather than
# by position, removing one instance from the map never renames or
# recreates the others - the failure mode you get with `count`.
resource "aws_instance" "this" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  vpc_security_group_ids = each.value.vpc_security_group_ids

  # try(expr, fallback) returns the first argument that evaluates without
  # error. These attributes are declared optional() with no default, so
  # they arrive as null when omitted; passing null to the provider means
  # "leave this unset" rather than "set it to empty".
  key_name             = try(each.value.key_name, null)
  iam_instance_profile = try(each.value.iam_instance_profile, null)

  private_ip = try(each.value.private_ip, null)

  associate_public_ip_address = try(
    each.value.associate_public_ip_address,
    false
  )

  # DYNAMIC BLOCK: root_block_device is a nested block, not an argument, so
  # it cannot simply be set to null. A dynamic block generates the nested
  # block zero or more times from a collection - here, an empty list when
  # the caller omitted root_block_device (no block emitted, AWS uses the
  # AMI default) or a one-element list when they supplied it.
  # Inside content{}, the iterator is named after the block, so
  # root_block_device.value is the object the caller passed.
  dynamic "root_block_device" {
    for_each = try(each.value.root_block_device, null) == null ? [] : [each.value.root_block_device]

    content {
      volume_size           = root_block_device.value.volume_size
      volume_type           = root_block_device.value.volume_type
      encrypted             = root_block_device.value.encrypted
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }

  # Per-instance tag map precomputed in locals.tf and looked up by key.
  tags = local.tags[each.key]
}