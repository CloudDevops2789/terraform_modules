##################################################################################################
# Explicit Subnet and Route Table Topology
##################################################################################################
#
# These resources support VPCs requiring multiple subnet roles, multiple
# subnets in one Availability Zone, and explicit subnet-to-route-table
# associations.
#
# The caller defines the topology. The module does not infer firewall,
# application, database, endpoint, Transit Gateway, or egress roles.

##################################################################################################
# Advanced route tables
##################################################################################################

resource "aws_route_table" "advanced" {

  # Caller-defined map keys provide stable Terraform resource identities.
  #
  # Adding or removing one route table does not shift the addresses of any
  # other route tables.
  for_each = local.advanced_route_tables

  vpc_id = aws_vpc.this.id

  # Names and resource-specific tag precedence are normalized in locals.tf.
  tags = each.value.tags
}

##################################################################################################
# Advanced subnets
##################################################################################################

resource "aws_subnet" "advanced" {

  # One subnet is created for every advanced subnet definition.
  #
  # Unlike the legacy interface, multiple subnets may use the same
  # Availability Zone because placement is explicit rather than inferred
  # from the subnet's position in a sorted map.
  for_each = local.advanced_subnets

  vpc_id = aws_vpc.this.id

  cidr_block = each.value.cidr_block

  # Exactly one of these values is non-null. variables.tf validates the
  # caller's selector, while locals.tf resolves an AZ index into an AZ name.
  availability_zone    = each.value.availability_zone
  availability_zone_id = each.value.availability_zone_id

  # This option alone does not make a subnet public. Public reachability also
  # requires an Internet Gateway and an explicit route to that gateway.
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = each.value.tags
}

##################################################################################################
# Explicit subnet-to-route-table associations
##################################################################################################

resource "aws_route_table_association" "advanced" {

  # Iterate over the created subnet resources so Terraform automatically
  # waits until each subnet exists before creating its association.
  for_each = aws_subnet.advanced

  subnet_id = each.value.id

  # The subnet references a caller-defined route-table key. This supports
  # route tables per AZ, per subnet group, or per individual subnet without
  # embedding any topology-specific assumptions in the module.
  route_table_id = aws_route_table.advanced[
    local.advanced_subnets[each.key].route_table_key
  ].id
}
