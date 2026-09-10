# Version pinning. required_version guards the Terraform CLI itself;
# required_providers pins the AWS provider. "~> 6.0" is a pessimistic
# constraint: any 6.x release is allowed, 7.0 is not - protecting you from
# breaking major-version changes. Exact versions are then locked in
# .terraform.lock.hcl for reproducible runs.
terraform {

  required_version = ">= 1.10.0"

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "~> 6.0"

    }

  }

}
