##################################################################################################
# Module Under Test: managed-microsoft-ad
##################################################################################################

module "managed_microsoft_ad" {
  source = "../../../modules/managed-microsoft-ad"

  domain_name = local.managed_ad.domain_name
  password    = var.managed_ad_password
  edition     = local.managed_ad.edition

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids_by_group["directory-services"]

  tags = local.org_tags
}
