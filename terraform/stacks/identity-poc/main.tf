################################################################################
# Minimal Managed AD Functional PoC
#
# Purpose:
#   Validate Managed AD user/group/password/Secrets Manager automation without
#   deploying the full IRE Platform topology.
#
# Placement:
#   Existing VPC + exactly two existing subnets in different AZs.
#
# Production remains:
#   Platform -> Identity -> Managed AD
################################################################################

module "managed_microsoft_ad" {
  source = "../../modules/managed-microsoft-ad"

  domain_name = var.domain_name
  short_name  = var.short_name
  password    = var.managed_ad_password
  edition     = var.edition

  enable_directory_data_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  client_cidr_blocks = []

  tags = var.tags
}
