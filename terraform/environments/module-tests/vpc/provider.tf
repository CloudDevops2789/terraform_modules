# Configures the AWS provider plugin: which region API calls go to and which
# credentials are used (picked up from the environment / shared config, since
# none are hardcoded here).
provider "aws" {

  region = var.aws_region

  # Provider default tags are applied to every supported resource created by
  # this test root. local.org_tags contains the mandatory enterprise tags and
  # any approved additional tags supplied through terraform.tfvars.
  default_tags {
    tags = local.org_tags
  }

}
