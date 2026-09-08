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

  monitoring              = each.value.monitoring
  disable_api_termination = each.value.disable_api_termination
  ebs_optimized           = try(each.value.ebs_optimized, null)

  # Always emit an explicit root block device so encryption is enforced
  # even when the caller does not customize the AMI root volume. A null
  # volume_size allows the provider/AMI default size to remain in effect.
  root_block_device {
    volume_size           = try(each.value.root_block_device.volume_size, null)
    volume_type           = each.value.root_block_device.volume_type
    iops                  = try(each.value.root_block_device.iops, null)
    throughput            = try(each.value.root_block_device.throughput, null)
    kms_key_id            = try(each.value.root_block_device.kms_key_id, null)
    encrypted             = each.value.root_block_device.encrypted
    delete_on_termination = each.value.root_block_device.delete_on_termination
  }

  metadata_options {
    http_endpoint               = each.value.metadata_options.http_endpoint
    http_tokens                 = each.value.metadata_options.http_tokens
    http_put_response_hop_limit = each.value.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = each.value.metadata_options.instance_metadata_tags
  }

  # Per-instance tag map precomputed in locals.tf and looked up by key.
  tags = local.tags[each.key]
}
