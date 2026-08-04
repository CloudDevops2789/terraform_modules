locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  default_tags = {
    TestedModule = "security-group"
  }

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # A security group must belong to a VPC. A minimal VPC exists here only
  # to give the group a real vpc_id; the VPC itself is not under test.
  vpc = {
    vpc_name                = "module-test-sg-vpc"
    cidr_block              = "10.253.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.253.11.0/24"
    }
  }

  ##################################################################################################
  # Security Groups and Rules Under Test
  ##################################################################################################
  # security-group and security-group-rule are two separate modules that
  # are always used together (a rule cannot exist without a group to attach
  # to), so this test validates both. One group with one ingress and one
  # egress rule is the minimum shape that exercises: group creation, the
  # ingress/egress split in security-group-rule's locals, and both standalone
  # rule resource types.
  security_groups = {
    tiers = {
      management = {
        description = "Module test - Security Group"
      }
    }

    rules = {
      ssh_ingress = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_ipv4   = "10.253.0.0/16"
      }

      all_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }
}
