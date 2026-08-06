##################################################################################################
# Supporting EC2 Instance
##################################################################################################
# The AWS Backup Selection module protects existing resources by ARN - it
# needs at least one real resource to reference. This single instance
# exists only to be that resource; it is not under test.
module "ec2" {

  source = "../../../modules/ec2"

  tags = local.org_tags
  instances = {
    workload = {
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

      subnet_id                   = module.vpc.subnet_ids["private-a"]
      associate_public_ip_address = local.ec2.associate_public_ip_address

      vpc_security_group_ids = [
        module.security_group.security_group_ids["workload"]
      ]
    }
  }
}
