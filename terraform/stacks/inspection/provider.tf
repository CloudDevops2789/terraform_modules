##################################################################################################
# AWS Provider
##################################################################################################
#
# aws_region is injected by the lifecycle runtime.
# Organization default tags are Git-controlled through common-tags.tfvars.
##################################################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.org_tags
  }
}
