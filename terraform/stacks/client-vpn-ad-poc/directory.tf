module "managed_microsoft_ad" {
  source = "../../modules/managed-microsoft-ad"

  domain_name = var.domain_name
  password    = var.managed_ad_password
  edition     = var.directory_edition

  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.subnet_ids["directory-a"],
    module.vpc.subnet_ids["directory-b"],
  ]

  client_cidr_blocks = [
    var.vpc_cidr_block,
    var.client_cidr_block,
  ]

  tags = local.tags
}
