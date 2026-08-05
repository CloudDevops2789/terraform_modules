##################################################################################################
# Supporting Security Group
##################################################################################################
# The supporting EC2 instance requires a security group. Not under test.
module "security_group" {

  source = "../../../modules/security-group"

  default_tags = local.default_tags

  security_groups = {
    workload = {
      description = local.security_group.description
      vpc_id      = module.vpc.vpc_id
    }
  }
}
