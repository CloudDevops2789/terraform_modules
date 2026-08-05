##################################################################################################
# Module Under Test: ec2
##################################################################################################
# terraform/modules/ec2 is the module this environment exists to validate.
# A single instance exercises the module's for_each, tag merging, and
# default resolution for every optional attribute (key_name,
# iam_instance_profile, private_ip, root_block_device) left unset here.
module "ec2" {

  source = "../../../modules/ec2"

  tags = local.org_tags
  instances = {

    management = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.vpc.public_subnet_map["public-a"]
      associate_public_ip_address = local.ec2.associate_public_ip_address
      key_name                    = module.key_pair.key_names["management"]
      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }
  }
}
