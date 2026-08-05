##################################################################################################
# Module Under Test: kms
##################################################################################################
# terraform/modules/kms is the module this environment exists to validate.
# No supporting resources are required - the module resolves the calling
# identity itself and builds its own key policy internally.
module "kms" {

  source = "../../../modules/kms"

  description = local.kms.description

  alias = local.kms.alias

  tags = local.org_tags
}
