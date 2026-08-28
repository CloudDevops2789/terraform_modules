module "managed_microsoft_ad" {
  source = "../../modules/managed-microsoft-ad"

  domain_name = var.domain_name
  password    = var.managed_ad_password
  edition     = var.directory_edition

  # The bootstrap job manages the proof user and group through this API.
  enable_directory_data_access = true

  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.subnet_ids["directory-a"],
    module.vpc.subnet_ids["directory-b"],
  ]

  # AWS Directory Service owns the baseline rules for the directory VPC CIDR.
  # Add only networks external to that VPC to avoid duplicate AWS-managed rules.
  client_cidr_blocks = [var.client_cidr_block]

  tags = local.tags
}
