locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied on top of the provider's default_tags so resources created by
  # this test are identifiable as throwaway module-validation infrastructure.
  default_tags = {
    TestedModule = "vpc"
  }

  ##################################################################################################
  # VPC Under Test
  ##################################################################################################
  # This is the ONLY thing this environment exists to validate: that the vpc
  # module accepts these inputs and successfully creates a VPC with a
  # private subnet, a private route table, and the association between them.
  #
  # A single private subnet is the minimum shape that exercises every
  # required code path in the module (VPC, subnet, route table,
  # association) without exercising the optional public-subnet / Internet
  # Gateway path, which is not needed to answer "does this module deploy?".
  vpc = {
    vpc_name                = "module-test-vpc"
    cidr_block              = "10.250.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.250.11.0/24"
    }
  }
}
