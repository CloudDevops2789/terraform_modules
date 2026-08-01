locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to resources created by this environment. Deployment-level
  # configuration, not infrastructure logic.
  default_tags = {
    Environment = "Sandbox"
    Project     = "AWS-IRE"
    Owner       = "CloudEngineering"
    ManagedBy   = "Terraform"
  }

  ##################################################################################################
  # Recovery Access VPC
  ##################################################################################################
  # Static network definition for the Recovery Access VPC used by this
  # environment to exercise the Client VPN setup. Deployment configuration,
  # not infrastructure logic.
  recovery_access = {
    vpc_name                = "recovery-access"
    cidr_block              = "10.100.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.100.11.0/24"
      private-b = "10.100.12.0/24"
    }
  }

  ##################################################################################################
  # Security Groups
  ##################################################################################################
  # Static configuration for the management security group and its
  # ingress/egress rules. security_group_id values are relationships and
  # remain inline in main.tf.
  security_groups = {

    tiers = {
      management = {
        description = "Management"
      }
    }

    rules = {
      management_ssh = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_ipv4   = "0.0.0.0/0"
      }

      management_ping = {
        ip_protocol = "icmp"
        from_port   = 8
        to_port     = -1
        cidr_ipv4   = "0.0.0.0/0"
      }

      management_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  }

  ##################################################################################################
  # EC2
  ##################################################################################################
  # Static instance configuration for the single management instance used to
  # validate Client VPN connectivity. Placement, key material, and security
  # group membership are relationships and remain inline in main.tf.
  ec2 = {
    ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type = "t3.micro"
  }

  ##################################################################################################
  # Client VPN
  ##################################################################################################
  # Static Client VPN configuration used to validate certificate-based
  # authentication and connectivity into the Recovery Access VPC. VPC/subnet
  # associations, security group membership, and the authorization target
  # CIDR are relationships and remain inline in main.tf.
  client_vpn = {
    name = "ire-client-vpn"

    server_certificate_arn     = "arn:aws:acm:us-east-1:781436988948:certificate/5bf9218b-6fbc-4cb3-a02b-0eb291d771b5"
    root_certificate_chain_arn = "arn:aws:acm:us-east-1:781436988948:certificate/fc51c80f-aa8a-4830-ad23-5a3f42ffd26f"

    client_cidr_block     = "192.168.0.0/16"
    split_tunnel          = true
    transport_protocol    = "udp"
    vpn_port              = 443
    dns_servers           = []
    session_timeout_hours = 8
    authorize_all_groups  = true
  }
}
