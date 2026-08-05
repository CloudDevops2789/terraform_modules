provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.org_tags
  }
}