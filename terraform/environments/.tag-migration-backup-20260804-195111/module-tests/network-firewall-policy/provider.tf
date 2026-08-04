##################################################################################################
# AWS Provider
##################################################################################################
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "ModuleTest"
      ManagedBy   = "Terraform"
      Owner       = "CloudEngineering"
      Project     = "AWS-IRE"
    }
  }
}
