# Configures the AWS provider plugin: which region API calls go to and which
# credentials are used (picked up from the environment / shared config, since
# none are hardcoded here - the right approach).
provider "aws" {
  region = var.aws_region

  # default_tags are applied by the PROVIDER to every taggable resource it
  # creates, without repeating them on each resource. Resource-level tags are
  # merged on top and win on key conflicts.
  default_tags {
    tags = local.org_tags
  }
}
