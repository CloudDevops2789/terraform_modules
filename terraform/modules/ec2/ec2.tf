resource "aws_instance" "this" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  vpc_security_group_ids = each.value.vpc_security_group_ids

  key_name             = try(each.value.key_name, null)
  iam_instance_profile = try(each.value.iam_instance_profile, null)

  private_ip = try(each.value.private_ip, null)

  associate_public_ip_address = try(
    each.value.associate_public_ip_address,
    false
  )

  dynamic "root_block_device" {
    for_each = try(each.value.root_block_device, null) == null ? [] : [each.value.root_block_device]

    content {
      volume_size           = root_block_device.value.volume_size
      volume_type           = root_block_device.value.volume_type
      encrypted             = root_block_device.value.encrypted
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }

  tags = local.tags[each.key]
}