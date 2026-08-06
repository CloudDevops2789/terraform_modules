##################################################################################################
# Supporting VPC
##################################################################################################
# AWS Managed Microsoft AD requires exactly two subnet IDs in two different
# Availability Zones. The supporting VPC uses the keyed VPC interface and
# creates no Internet Gateway or routes.

module "vpc" {
  source = "../../../modules/vpc"

  vpc_name   = local.vpc.vpc_name
  cidr_block = local.vpc.cidr_block

  route_tables = local.vpc.route_tables
  subnets      = local.vpc.subnets

  create_internet_gateway = false

  tags = local.org_tags
}
