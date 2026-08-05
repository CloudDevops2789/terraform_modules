##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created here because the Client VPN module requires
# subnets for endpoint associations. The VPC itself is not under test.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.default_tags
}
