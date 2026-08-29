module "vpc" {
  source = "../../modules/vpc"

  vpc_name   = "${local.name_prefix}-vpc"
  cidr_block = var.vpc_cidr_block

  route_tables = local.route_tables
  subnets      = local.subnets

  create_internet_gateway = false

  tags = local.tags
}

module "security_group" {
  source = "../../modules/security-group"

  security_groups = {
    client-vpn = {
      name        = "${local.name_prefix}-endpoint"
      description = "Client VPN endpoint for the isolated Managed AD proof"
      vpc_id      = module.vpc.vpc_id
    }
    windows-test = {
      name        = "${local.name_prefix}-windows"
      description = "Private Windows validation instance for the Client VPN proof"
      vpc_id      = module.vpc.vpc_id
    }
  }

  tags = local.tags
}

module "security_group_rule" {
  source = "../../modules/security-group-rule"

  rules = merge({
    client-vpn-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["client-vpn"]
      description       = "Allow authenticated VPN traffic to approved VPC destinations"
      ip_protocol       = "-1"
      cidr_ipv4         = var.vpc_cidr_block
    }
    windows-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["windows-test"]
      description       = "Allow the test host to use VPC-local directory services"
      ip_protocol       = "-1"
      cidr_ipv4         = var.vpc_cidr_block
    }
    }, {
    for subnet_key in local.client_vpn_association_subnet_keys :
    "windows-rdp-from-vpn-${subnet_key}" => {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["windows-test"]
      description       = "RDP from the Client VPN association subnet"
      ip_protocol       = "tcp"
      from_port         = 3389
      to_port           = 3389
      cidr_ipv4         = local.subnets[subnet_key].cidr_block
    }
    }, {
    for subnet_key in local.client_vpn_association_subnet_keys :
    "windows-icmp-from-vpn-${subnet_key}" => {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["windows-test"]
      description       = "ICMP from the Client VPN association subnet"
      ip_protocol       = "icmp"
      from_port         = 8
      to_port           = -1
      cidr_ipv4         = local.subnets[subnet_key].cidr_block
    }
  })
}
