##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created here because a security group must be attached
# to a real VPC. The VPC itself is not under test.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.default_tags
}
