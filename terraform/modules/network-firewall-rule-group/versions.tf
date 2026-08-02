##################################################################################################
# Terraform
##################################################################################################
# Defines the Terraform and provider versions required by this module.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}