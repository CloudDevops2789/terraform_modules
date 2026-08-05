module "recovery_access" {

  source = "../../modules/vpc"

  tags = local.org_tags

  vpc_name                = local.recovery_access.vpc_name
  cidr_block              = local.recovery_access.cidr_block
  availability_zone_count = local.recovery_access.availability_zone_count


  private_subnets = local.recovery_access.private_subnets
}

module "security_group" {

  source = "../../modules/security-group"

  tags = local.org_tags

  security_groups = {

    management = {
      description = local.security_groups.tiers.management.description
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

      ip_protocol = local.security_groups.rules.management_ssh.ip_protocol
      from_port   = local.security_groups.rules.management_ssh.from_port
      to_port     = local.security_groups.rules.management_ssh.to_port

      cidr_ipv4 = local.security_groups.rules.management_ssh.cidr_ipv4
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ping.ip_protocol
      from_port   = local.security_groups.rules.management_ping.from_port
      to_port     = local.security_groups.rules.management_ping.to_port

      cidr_ipv4 = local.security_groups.rules.management_ping.cidr_ipv4
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_egress.ip_protocol

      cidr_ipv4 = local.security_groups.rules.management_egress.cidr_ipv4
    }
  }
}

module "key_pair" {

  source = "../../modules/key-pair"

  tags = local.org_tags
  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

}

module "ec2" {

  source = "../../modules/ec2"

  tags = local.org_tags

  instances = {

    management = {
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

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

  tags = local.org_tags

  name = local.client_vpn.name

  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn


  client_cidr_block = local.client_vpn.client_cidr_block

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

  split_tunnel       = local.client_vpn.split_tunnel
  transport_protocol = local.client_vpn.transport_protocol
  vpn_port           = local.client_vpn.vpn_port
  dns_servers        = local.client_vpn.dns_servers

  session_timeout_hours = local.client_vpn.session_timeout_hours

  authorization_rules = {
    #When we  move to IAM Identity Center (SAML), your interface barely changes.
    #you could extend the object with an optional group identifier
    #access_group_id = "cloud-admin"
    recovery_access = {

      target_network_cidr = module.recovery_access.vpc_cidr

      authorize_all_groups = local.client_vpn.authorize_all_groups

    }

  }

  routes = {}

}
