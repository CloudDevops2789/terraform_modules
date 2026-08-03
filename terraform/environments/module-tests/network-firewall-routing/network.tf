##################################################################################################
# Isolated Module-Test Network
##################################################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-vpc"
  })
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-igw"
  })
}
resource "aws_subnet" "workload" {
  availability_zone       = local.availability_zone
  cidr_block              = local.subnet_cidrs.workload
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-workload"
    Tier = "Workload"
  })
}
resource "aws_subnet" "firewall" {
  availability_zone       = local.availability_zone
  cidr_block              = local.subnet_cidrs.firewall
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-firewall"
    Tier = "NetworkFirewall"
  })
}
resource "aws_subnet" "transit" {
  availability_zone       = local.availability_zone
  cidr_block              = local.subnet_cidrs.transit
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-routing-transit"
    Tier = "TransitGateway"
  })
}
