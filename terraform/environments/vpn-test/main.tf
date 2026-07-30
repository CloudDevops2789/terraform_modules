module "recovery_access" {

  source = "../../modules/vpc"

  vpc_name                = "recovery-access"
  cidr_block              = "10.100.0.0/16"
  availability_zone_count = 2


  private_subnets = {
    private-a = "10.100.11.0/24"
    private-b = "10.100.12.0/24"
  }
}

module "security_group" {

  source = "../../modules/security-group"


  security_groups = {

    management = {
      description = "Management"
      vpc_id      = module.recovery_access.vpc_id
    }
  }

}

module "security_group_rule" {

  source = "../../modules/security-group-rule"

  rules = {

    management-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "icmp"
      from_port   = 8
      to_port     = -1

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }
  }
}

module "key_pair" {

  source = "../../modules/key-pair"

  default_tags = local.default_tags

  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

}

module "ec2" {

  source = "../../modules/ec2"



  instances = {

    management = {
      ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
      instance_type = "t3.micro"

      subnet_id                   = module.recovery_access.private_subnet_ids[1] # create on 2nd subnet and changed to private subnet to avoid public IPs in sandbox
      associate_public_ip_address = false                                        # true when we want public IPs on instances in this subnet

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }
  }
}

module "client_vpn" {

  source = "../../modules/client-vpn"

  name = "ire-client-vpn"

  server_certificate_arn     = "arn:aws:acm:us-east-1:781436988948:certificate/5bf9218b-6fbc-4cb3-a02b-0eb291d771b5"
  root_certificate_chain_arn = "arn:aws:acm:us-east-1:781436988948:certificate/fc51c80f-aa8a-4830-ad23-5a3f42ffd26f"


  client_cidr_block = "192.168.0.0/16"

  vpc_id = module.recovery_access.vpc_id

  network_associations = {

    az1 = {
      subnet_id = module.recovery_access.private_subnet_ids[0]
    }

    az2 = {
      subnet_id = module.recovery_access.private_subnet_ids[1]
    }

  }

  security_group_ids = [
    module.security_group.security_group_ids["management"]
  ]

  split_tunnel       = true
  transport_protocol = "udp"
  vpn_port           = 443
  dns_servers        = []

  session_timeout_hours = 8

  authorization_rules = {
    #When we  move to IAM Identity Center (SAML), your interface barely changes.  
    #you could extend the object with an optional group identifier 
    #access_group_id = "cloud-admin"
    recovery_access = {

      target_network_cidr = module.recovery_access.vpc_cidr

      authorize_all_groups = true

    }

  }

  routes = {}

}