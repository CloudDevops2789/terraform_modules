# Version pinning. required_version guards the Terraform CLI itself;
# required_providers pins the AWS and tls providers. "~> 6.0"/"~> 4.0" are
# pessimistic constraints: any matching major-version release is allowed, the
# next major version is not.
terraform {

  required_version = ">= 1.10.0"

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "~> 6.0"

    }

    # Used only to generate a throwaway self-signed CA and server certificate
    # so this test can supply the ACM ARNs the Client VPN module requires,
    # without a human manually uploading certificates first.
    tls = {

      source = "hashicorp/tls"

      version = "~> 4.0"

    }

  }

}
