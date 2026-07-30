############################################
# Client VPN Network Associations
############################################

# Associates the Client VPN endpoint with one or more subnets.
#
# AWS creates an Elastic Network Interface (ENI) inside each
# associated subnet.
#
# Using for_each allows the module to support any number of
# Availability Zones without modifying the resource definition.
#
# Example:
#
# target_subnet_ids = [
#   subnet-a,
#   subnet-b
# ]
#
# becomes
#
# aws_ec2_client_vpn_network_association.this["subnet-a"]
# aws_ec2_client_vpn_network_association.this["subnet-b"]
resource "aws_ec2_client_vpn_network_association" "this" {

  for_each = var.network_associations

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

  subnet_id = each.value.subnet_id

  timeouts {
    create = "30m"
    delete = "30m"
  }
  
}