##################################################################################################
# Isolated Module-Test VPC
##################################################################################################
# Firewall subnets are dedicated to Network Firewall endpoints. No workload resources or routing
# paths are created because this test validates firewall lifecycle and endpoint discovery only.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-vpc"
  })
}
resource "aws_subnet" "firewall" {
  for_each                = local.firewall_subnets
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-${each.key}"
    Tier = "NetworkFirewall"
  })
}
