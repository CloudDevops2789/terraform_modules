##################################################################################################
# Module Under Test: managed-microsoft-ad
##################################################################################################
# terraform/modules/managed-microsoft-ad is the module this environment
# exists to validate: an AWS Managed Microsoft AD directory deployed into
# two subnets of the supporting VPC.
module "managed_microsoft_ad" {

  source = "../../../modules/managed-microsoft-ad"

  domain_name = local.managed_ad.domain_name

  password = var.managed_ad_password

  edition = local.managed_ad.edition

  vpc_id = module.vpc.vpc_id

  subnet_ids = [
    module.vpc.private_subnet_map["private-a"],
    module.vpc.private_subnet_map["private-b"]
  ]

  tags = local.org_tags
}
