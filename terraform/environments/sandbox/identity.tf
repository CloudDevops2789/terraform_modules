############################################################
# Identity
############################################################

/*module "managed_microsoft_ad" {
  source = "../../modules/managed-microsoft-ad"

  domain_name = "recovery.example.com"

  password = var.managed_ad_password

  edition = "Enterprise"

  vpc_id = module.core_recovery.vpc_id

  subnet_ids = [
    module.core_recovery.private_subnet_ids[0],
    module.core_recovery.private_subnet_ids[1]
  ]

  tags       = local.org_tags
  depends_on = [module.core_recovery]
}*/
