############################################
# Client VPN Routes
############################################

# Client VPN routes tell the endpoint HOW to reach destination
# networks after a client has connected.
#
# Unlike Authorization Rules, routes are forwarding decisions.
#
# One route is created for each entry supplied by the root module.
#
# Example:
#
# Laptop
#    │
# Client VPN
#    │
# Route
#    │
# Recovery Access VPC
#    │
# Transit Gateway
#    │
# Core Recovery
#
resource "aws_ec2_client_vpn_route" "this" {

  for_each = var.routes

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id

  destination_cidr_block = each.value.destination_cidr_block

  target_vpc_subnet_id = each.value.target_subnet_id

  description = try(each.value.description, null)
}