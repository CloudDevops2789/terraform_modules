##################################################################################################
# VPC Route Table Associations
##################################################################################################
# Gateway associations support ingress routing through Network Firewall. Subnet associations bind
# protected, firewall, NAT, and Transit Gateway attachment subnets to explicit route tables.
resource "aws_route_table_association" "this" {
  for_each       = local.route_table_associations
  gateway_id     = each.value.gateway_id
  route_table_id = each.value.route_table_id
  subnet_id      = each.value.subnet_id
  timeouts {
    create = each.value.timeouts.create
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}
