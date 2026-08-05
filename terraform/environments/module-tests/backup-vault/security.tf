##################################################################################################
# Supporting Security Group
##################################################################################################
# The supporting EC2 instance requires a security group. Not under test.
module "security_group" {

  source = "../../../modules/security-group"

  tags = local.org_tags
  security_groups = {
    workload = {
      description = local.security_group.description
      vpc_id      = module.vpc.vpc_id
    }
  }
}
