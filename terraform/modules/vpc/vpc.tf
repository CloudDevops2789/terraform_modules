##################################################################################################
# Virtual Private Cloud
##################################################################################################
#
# The VPC is the network boundary containing every subnet and route table
# created by this module.
#
# DNS support and DNS hostnames are enabled by default because private AWS
# endpoints, internal services, and workloads commonly depend on DNS.

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = local.vpc_tags
}
