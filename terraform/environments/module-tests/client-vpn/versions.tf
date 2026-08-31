# Version pinning. required_version guards the Terraform CLI itself and
# required_providers pins the AWS provider.
terraform {

  required_version = ">= 1.10.0"

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "~> 6.0"

    }

  }

}
