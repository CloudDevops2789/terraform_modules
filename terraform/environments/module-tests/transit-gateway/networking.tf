##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created here because the Transit Gateway module requires
# a real VPC ID and subnet IDs to attach to. The VPC itself is not under
# test - see locals.tf for why one private subnet is sufficient.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.org_tags
}
