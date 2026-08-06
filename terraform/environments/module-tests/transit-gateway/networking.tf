##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created because the Transit Gateway module requires a real
# VPC and subnet IDs for its attachment. The VPC itself is not under test.

module "vpc" {
  source = "../../../modules/vpc"

  vpc_name   = local.vpc.vpc_name
  cidr_block = local.vpc.cidr_block

  route_tables = local.vpc.route_tables
  subnets      = local.vpc.subnets

  create_internet_gateway = false

  tags = local.org_tags
}
