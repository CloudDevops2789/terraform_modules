##################################################################################################
# Isolated Module-Test Network
##################################################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-logging-vpc"
  })
}
resource "aws_subnet" "firewall" {
  availability_zone       = local.availability_zone
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "module-test-network-firewall-logging-subnet"
    Tier = "NetworkFirewall"
  })
}
