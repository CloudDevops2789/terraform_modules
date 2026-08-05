##################################################################################################
# Route Tables
##################################################################################################
# Routes are intentionally omitted from these resources because the module under test manages them
# as standalone aws_route resources.
resource "aws_route_table" "workload" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-workload"
  })
}
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-firewall"
  })
}
resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-ingress"
  })
}
resource "aws_route_table" "transit" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-transit"
  })
}
