##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created here because the EC2 module requires a real
# subnet_id to launch into. The VPC itself is not under test.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets
  public_subnets  = local.vpc.public_subnets

  tags = local.org_tags
}
