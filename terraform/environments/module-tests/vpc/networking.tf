##################################################################################################
# Module Under Test: VPC
##################################################################################################
#
# This root validates the reusable VPC module using one scalable topology
# interface.
#
# The module receives:
#
# - one VPC CIDR;
# - caller-defined route tables;
# - caller-defined subnets;
# - explicit subnet-to-route-table relationships.
#
# The Internet Gateway is enabled to validate the module's optional owned
# resource. The VPC module must not create Internet Gateway routes automatically.

module "vpc" {
  source = "../../../modules/vpc"

  vpc_name   = local.vpc.vpc_name
  cidr_block = local.vpc.cidr_block

  route_tables = local.vpc.route_tables
  subnets      = local.vpc.subnets

  create_internet_gateway = true

  tags = local.org_tags
}
