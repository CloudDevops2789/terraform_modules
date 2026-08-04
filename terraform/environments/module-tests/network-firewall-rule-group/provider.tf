##################################################################################################
# AWS Provider
##################################################################################################
# Provider configuration belongs to this root module rather than the reusable module under test.
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.default_tags
  }
}
