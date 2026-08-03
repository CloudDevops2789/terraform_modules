##################################################################################################
# VPC Route Outputs
##################################################################################################
output "vpc_routes" {
  description = "VPC route attributes keyed by logical identifiers."
  value = {
    for key, route in aws_route.this : key => {
      id                          = route.id
      route_table_id              = route.route_table_id
      destination_cidr_block      = route.destination_cidr_block
      destination_ipv6_cidr_block = route.destination_ipv6_cidr_block
      destination_prefix_list_id  = route.destination_prefix_list_id
      state                       = route.state
      origin                      = route.origin
      carrier_gateway_id          = route.carrier_gateway_id
      core_network_arn            = route.core_network_arn
      egress_only_gateway_id      = route.egress_only_gateway_id
      gateway_id                  = route.gateway_id
      local_gateway_id            = route.local_gateway_id
      nat_gateway_id              = route.nat_gateway_id
      network_interface_id        = route.network_interface_id
      odb_network_arn             = route.odb_network_arn
      transit_gateway_id          = route.transit_gateway_id
      vpc_endpoint_id             = route.vpc_endpoint_id
      vpc_peering_connection_id   = route.vpc_peering_connection_id
    }
  }
}
output "vpc_route_ids" {
  description = "VPC route IDs keyed by logical identifiers."
  value = {
    for key, route in aws_route.this : key => route.id
  }
}
##################################################################################################
# Route Table Association Outputs
##################################################################################################
output "route_table_associations" {
  description = "VPC route table association attributes keyed by logical identifiers."
  value = {
    for key, association in aws_route_table_association.this : key => {
      id             = association.id
      route_table_id = association.route_table_id
      subnet_id      = association.subnet_id
      gateway_id     = association.gateway_id
    }
  }
}
##################################################################################################
# Transit Gateway Routing Outputs
##################################################################################################
output "transit_gateway_routes" {
  description = "Transit Gateway route attributes keyed by logical identifiers."
  value = {
    for key, route in aws_ec2_transit_gateway_route.this : key => {
      id                             = route.id
      destination_cidr_block         = route.destination_cidr_block
      blackhole                      = route.blackhole
      transit_gateway_attachment_id  = route.transit_gateway_attachment_id
      transit_gateway_route_table_id = route.transit_gateway_route_table_id
    }
  }
}
output "transit_gateway_route_table_associations" {
  description = "Transit Gateway route table association IDs keyed by logical identifiers."
  value = {
    for key, association in aws_ec2_transit_gateway_route_table_association.this :
    key => association.id
  }
}
output "transit_gateway_route_table_propagations" {
  description = "Transit Gateway route table propagation IDs keyed by logical identifiers."
  value = {
    for key, propagation in aws_ec2_transit_gateway_route_table_propagation.this :
    key => propagation.id
  }
}
