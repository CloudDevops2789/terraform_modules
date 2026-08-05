##################################################################################################
# Module Under Test: vpc
##################################################################################################
# terraform/modules/vpc is the module this environment exists to validate.
# Every input below is either a static value from locals.tf (deployment
# configuration) or omitted entirely to exercise the module's own defaults
# (public_subnets, DNS settings, Transit Gateway routes) - there is nothing
# here for those inputs to depend on, since this environment has no other
# infrastructure.
module "vpc" {

  source = "../../../modules/vpc"

  vpc_name                = local.vpc.vpc_name
  cidr_block              = local.vpc.cidr_block
  availability_zone_count = local.vpc.availability_zone_count

  private_subnets = local.vpc.private_subnets

  tags = local.org_tags
}
