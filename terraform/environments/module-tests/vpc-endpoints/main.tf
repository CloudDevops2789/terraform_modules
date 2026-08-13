module "vpc_endpoints" {
  source = "../../../modules/vpc-endpoints"

  vpc_id = "vpc-0123456789abcdef0"

  interface_endpoints = {
    ssm = {
      name = "example-ssm"

      service_name = "com.amazonaws.us-east-1.ssm"

      subnet_ids = [
        "subnet-0123456789abcdef0",
        "subnet-0123456789abcdef1"
      ]

      security_group_ids = [
        "sg-0123456789abcdef0"
      ]

      private_dns_enabled = true
    }

    ssmmessages = {
      name = "example-ssmmessages"

      service_name = "com.amazonaws.us-east-1.ssmmessages"

      subnet_ids = [
        "subnet-0123456789abcdef0",
        "subnet-0123456789abcdef1"
      ]

      security_group_ids = [
        "sg-0123456789abcdef0"
      ]

      private_dns_enabled = true
    }
  }

  gateway_endpoints = {
    s3 = {
      name = "example-s3"

      service_name = "com.amazonaws.us-east-1.s3"

      route_table_ids = [
        "rtb-0123456789abcdef0",
        "rtb-0123456789abcdef1"
      ]
    }
  }

  tags = {
    org_environment = "test"
    org_managed_by  = "Terraform"
  }
}
