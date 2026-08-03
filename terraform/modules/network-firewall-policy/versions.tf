##################################################################################################
# Terraform and Provider Requirements
##################################################################################################
# Provider authentication, Region selection, and provider-level default tags remain the
# responsibility of the consuming Terraform root module.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.38, < 7.0"
    }
  }
}
