locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    "org_it_cost_center"       = var.org_it_cost_center
    "org_department"           = var.org_department
    "org_cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "org_business_criticality" = var.org_business_criticality
    "org_environment"          = var.org_environment
    "org_data_classification"  = var.org_data_classification
    "org_project_name"         = var.org_project_name
    "org_managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # The ec2 module places instances into a subnet it does not create - a
  # minimal VPC with one subnet exists only to give the instance somewhere
  # to live. The VPC itself is not under test.
  vpc = {
    vpc_name   = "module-test-ec2-vpc"
    cidr_block = "10.252.0.0/16"

    route_tables = {
      public-a = {
        group = "public"
      }

      private-a = {
        group = "private"
      }
    }

    subnets = {
      public-a = {
        cidr_block              = "10.252.10.0/24"
        availability_zone_index = 0
        group                   = "public"
        route_table_key         = "public-a"
        map_public_ip_on_launch = true
      }

      private-a = {
        cidr_block              = "10.252.11.0/24"
        availability_zone_index = 0
        group                   = "private"
        route_table_key         = "private-a"
      }
    }
  }

  ##################################################################################################
  # Supporting Security Group
  ##################################################################################################
  # aws_instance requires a security group; the ec2 module does not create
  # one itself, so one is created here with no rules. AWS still attaches its
  # default allow-all egress rule automatically, which is all this test
  # needs. Ingress/egress rule behavior is validated by the security-group
  # module test, not here.
  security_groups = {
    tiers = {
      management = {
        description = "Module test - EC2"
      }
    }
    rules = {
      ssh_ingress = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_ipv4   = "0.0.0.0/0"
      }

      all_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }

  ##################################################################################################
  # EC2 Under Test
  ##################################################################################################
  # A single instance is the minimum shape that exercises the module's
  # for_each over var.instances, its tag-merging locals, and its optional
  # attributes resolving to their defaults (no key pair, no root block
  # device override, no public IP).
  ec2 = {
    ami                         = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type               = "t3.micro"
    associate_public_ip_address = true
  }
}
