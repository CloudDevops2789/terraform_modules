##################################################################################################
# Terraform and Provider Requirements
##################################################################################################
# Provider authentication and Region selection remain the responsibility of the consuming root.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.55, < 7.0"
    }
  }
}
