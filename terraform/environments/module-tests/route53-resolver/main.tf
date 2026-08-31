terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "route53_resolver" {
  source = "../../../modules/route53-resolver"

  name      = "example-private-dns"
  direction = "OUTBOUND"

  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ]

  security_group_ids = [
    "sg-0123456789abcdef0"
  ]

  forwarding_rules = {
    directory = {
      domain_name = "ad.example.internal"

      target_ips = [
        { ip = "10.20.1.10" },
        { ip = "10.20.2.10" }
      ]

      vpc_ids = {
        administration = "vpc-0123456789abcdef0"
        workloads      = "vpc-0123456789abcdef1"
      }
    }
  }

  query_log_config_id = "rqlc-0123456789abcdef0"
  query_log_vpc_ids = {
    administration = "vpc-0123456789abcdef0"
    workloads      = "vpc-0123456789abcdef1"
  }

  tags = {
    org_environment = "ModuleTest"
    org_managed_by  = "Terraform"
  }
}
