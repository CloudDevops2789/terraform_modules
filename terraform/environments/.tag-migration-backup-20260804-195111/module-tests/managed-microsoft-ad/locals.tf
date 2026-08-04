locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  default_tags = {
    TestedModule = "managed-microsoft-ad"
  }

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # AWS Managed Microsoft AD requires exactly two subnet IDs in two
  # different Availability Zones (enforced by the module's own variable
  # validation). A minimal VPC with two private subnets exists only to
  # satisfy that requirement; the VPC itself is not under test.
  vpc = {
    vpc_name                = "module-test-ad-vpc"
    cidr_block              = "10.249.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.249.11.0/24"
      private-b = "10.249.12.0/24"
    }
  }

  ##################################################################################################
  # Managed Microsoft AD Under Test
  ##################################################################################################
  # The directory's domain name is static deployment configuration and
  # belongs here. Its password is a secret and is intentionally kept out
  # of locals.tf - see variables.tf and terraform.tfvars.example.
  managed_ad = {
    domain_name = "moduletest.example.com"
    edition     = "Standard" # cheapest edition; sufficient to prove the module deploys
  }
}
