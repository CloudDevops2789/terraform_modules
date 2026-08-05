##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC with two private subnets in two Availability Zones is
# created here because AWS Managed Microsoft AD requires exactly two
# subnet IDs in two different AZs. The VPC itself is not under test.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.org_tags
}
