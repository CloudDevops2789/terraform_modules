##################################################################################################
# Supporting Transit Gateway
##################################################################################################
resource "aws_ec2_transit_gateway" "this" {
  description                     = "Supports Network Firewall routing module validation."
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing"
  })
}
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids                                      = [aws_subnet.transit.id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-vpc"
  })
}
resource "aws_ec2_transit_gateway_route_table" "association" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-association"
  })
}
resource "aws_ec2_transit_gateway_route_table" "propagation" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-propagation"
  })
}
