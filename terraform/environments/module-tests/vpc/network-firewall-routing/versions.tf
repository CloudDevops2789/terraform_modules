##################################################################################################
# Terraform and Provider Requirements
##################################################################################################
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.55, < 7.0"
    }
  }
}
