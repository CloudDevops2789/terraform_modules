# Configures the AWS provider plugin: which region API calls go to and which
# credentials are used (picked up from the environment / shared config, since
# none are hardcoded here).
provider "aws" {

  region = var.aws_region

  # default_tags are applied by the PROVIDER to every taggable resource it
  # creates. Environment = "ModuleTest" keeps these throwaway resources
  # visually distinct from sandbox/vpn-test in the AWS console and in cost
  # reports, since nothing here is meant to be long-lived.
  default_tags {
    tags = local.default_tags
  }

}

# The tls provider has no configuration of its own - it generates key
# material locally rather than calling any remote API. It exists here only
# to satisfy the Client VPN module's certificate requirement (see
# certificates.tf); certificate generation is not the focus of this test.
provider "tls" {}
