################################################################################
# AWS Provider
#
# var.aws_region
#   -> declared in variables.tf
#   -> injected by AAP terraform/tasks/runtime_variables.yml
#
# local.org_tags
#   -> derived in locals.tf from organization tagging variables
#   -> applied automatically to supported AWS resources through default_tags
################################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.org_tags
  }
}
