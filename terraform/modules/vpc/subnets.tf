##################################################################################################
# Subnets
##################################################################################################
#
# One subnet is created for every entry in var.subnets.
#
# The caller-defined map key becomes the stable Terraform identity:
#
#   var.subnets["firewall-a"]
#
# creates:
#
#   aws_subnet.this["firewall-a"]
#
# Multiple subnets may use the same Availability Zone, group, or route table.
# Adding another subnet does not renumber or recreate existing subnets.

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  cidr_block = each.value.cidr_block

  # Only one of these values is populated.
  #
  # An AZ index is converted into an AZ name in locals.tf.
  # An explicit AZ ID remains an AZ ID so multi-account deployments can align
  # workloads with the same physical Availability Zone.
  availability_zone    = each.value.availability_zone
  availability_zone_id = each.value.availability_zone_id

  # This setting controls automatic public-IP assignment only.
  #
  # It does not make the subnet public. Public reachability also requires an
  # Internet Gateway and an explicit route to that gateway.
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = each.value.tags

  lifecycle {
    # An index larger than the number of AZs available in the selected region
    # resolves to null in locals.tf. This produces a clear Terraform error
    # instead of allowing AWS to select an unintended Availability Zone.
    precondition {
      condition = (
        each.value.availability_zone != null ||
        each.value.availability_zone_id != null
      )

      error_message = "Subnet ${each.key} could not resolve its Availability Zone. Verify availability_zone, availability_zone_id, or availability_zone_index."
    }
  }
}
