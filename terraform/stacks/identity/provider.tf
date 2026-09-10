################################################################################
# AWS Provider
#
# var.aws_region
#   -> declared in variables.tf
#   -> populated by the approved AAP runtime-variable flow
#
# local.org_tags
#   -> derived in locals.tf
#   -> applied through AWS provider default_tags
################################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.org_tags
  }
}
