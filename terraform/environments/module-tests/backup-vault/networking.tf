##################################################################################################
# Supporting VPC
##################################################################################################
# A minimal VPC is created here so the supporting EC2 instance (the
# resource AWS Backup protects) has somewhere to launch. Not under test.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.default_tags
}
