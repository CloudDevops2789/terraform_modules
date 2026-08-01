##################################################################################################
# Supporting Security Group
##################################################################################################
# The Client VPN endpoint requires a security group for traffic leaving its
# ENIs toward VPC resources. Only the minimum required rules are configured
# because security groups are not the focus of this test - AWS's automatic
# default allow-all egress rule is all that's needed here.
module "security_group" {

  source = "../../../modules/security-group"

  default_tags = local.default_tags

  security_groups = {
    vpn = {
      description = local.security_group.description
      vpc_id      = module.vpc.vpc_id
    }
  }
}
