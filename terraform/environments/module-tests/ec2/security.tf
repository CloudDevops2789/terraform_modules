##################################################################################################
# Supporting Security Group
##################################################################################################
# The EC2 instance under test requires a security group to attach to. Only
# the minimum required security group is created because security groups
# and their rules are not the focus of this test (see the security-group/
# module test for that).
module "security_group" {

  source = "../../../modules/security-group"

  default_tags = local.default_tags

  security_groups = {
    management = {
      description = local.security_group.description
      vpc_id      = module.vpc.vpc_id
    }
  }
}
