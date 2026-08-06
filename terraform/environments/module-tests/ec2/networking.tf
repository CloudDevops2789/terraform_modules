##################################################################################################
# Supporting VPC
##################################################################################################
# A supporting VPC provides explicit public and private subnet identities for
# the EC2 module test. The Internet Gateway is created without routes because
# routing behaviour is outside the VPC module and is not under test here.

module "vpc" {
  source = "../../../modules/vpc"

  vpc_name   = local.vpc.vpc_name
  cidr_block = local.vpc.cidr_block

  route_tables = local.vpc.route_tables
  subnets      = local.vpc.subnets

  create_internet_gateway = true

  tags = local.org_tags
}
