##################################################################################################
# Recovery Access VPC
##################################################################################################

module "recovery_access" {
  source = "../../modules/vpc"

  vpc_name   = local.recovery_access.vpc_name
  cidr_block = local.recovery_access.cidr_block

  route_tables = local.recovery_access.route_tables
  subnets      = local.recovery_access.subnets

  # Recovery Access remains private. The VPC module creates no routes.
  create_internet_gateway = false

  tags = local.org_tags
}

##################################################################################################
# Security Groups
##################################################################################################

module "security_group" {
  source = "../../modules/security-group"

  security_groups = {
    management = {
      description = local.security_groups.tiers.management.description
      vpc_id      = module.recovery_access.vpc_id
    }
  }

  tags = local.org_tags
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
      cidr_ipv4   = local.security_groups.rules.management_ssh.cidr_ipv4
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_ping.ip_protocol
      from_port   = local.security_groups.rules.management_ping.from_port
      to_port     = local.security_groups.rules.management_ping.to_port
      cidr_ipv4   = local.security_groups.rules.management_ping.cidr_ipv4
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = local.security_groups.rules.management_egress.ip_protocol
      cidr_ipv4   = local.security_groups.rules.management_egress.cidr_ipv4
    }
  }
}

##################################################################################################
# Key Pair
##################################################################################################

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Management EC2 Instance
##################################################################################################

module "ec2" {
  source = "../../modules/ec2"

  instances = {
    management = {
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

      # Consume a stable caller-defined subnet key rather than a list position.
      subnet_id                   = module.recovery_access.subnet_ids["admin-b"]
      associate_public_ip_address = false

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Client VPN
##################################################################################################

module "client_vpn" {
  source = "../../modules/client-vpn"

  name = local.client_vpn.name

  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn

  client_cidr_block = local.client_vpn.client_cidr_block
  vpc_id            = module.recovery_access.vpc_id

  # Every subnet assigned to the client-vpn group becomes a target-network
  # association. Additional AZs can be added without changing this module call.
  network_associations = {
    for key, subnet in module.recovery_access.subnets :
    key => {
      subnet_id = subnet.id
    }
    if subnet.group == "client-vpn"
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
    recovery_access = {
      target_network_cidr  = module.recovery_access.vpc_cidr
      authorize_all_groups = local.client_vpn.authorize_all_groups
    }
  }

  # Routing policy remains explicit and outside the VPC module.
  routes = {}

  tags = local.org_tags
}
