##################################################################################################
# Identity
##################################################################################################
# Managed Microsoft AD remains disabled until its security workflow is
# approved. The directory-services group already spans two AZs.
# When this capability is enabled, restore the required password input and
# supply it through the approved AAP credential or enterprise secret-management path.

/*
# Purpose: Defines the optional AWS Managed Microsoft AD deployment for administrative identity testing.
# Change when: Enable or change it only after the identity use case, DNS design, and credential handling are approved.
module "managed_microsoft_ad" {
  source = "../../modules/managed-microsoft-ad"

  domain_name = "recovery.example.com"
  password    = var.managed_ad_password
  edition     = "Enterprise"

  vpc_id     = module.core_recovery.vpc_id
  subnet_ids = module.core_recovery.subnet_ids_by_group["directory-services"]

  tags = local.org_tags
}
*/
