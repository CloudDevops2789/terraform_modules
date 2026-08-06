locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to resources created by this environment. Deployment-level
  # configuration, not infrastructure logic.
  org_required_tags = {
    org_it_cost_center       = var.org_it_cost_center
    org_department           = var.org_department
    org_cmdb_calculated_app  = var.org_cmdb_calculated_app
    org_business_criticality = var.org_business_criticality
    org_environment          = var.org_environment
    org_data_classification  = var.org_data_classification
    org_project_name         = var.org_project_name
    org_managed_by           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # Recovery Access VPC
  ##################################################################################################
  # The environment owns subnet roles, CIDRs, Availability Zone placement,
  # and route-table relationships. The reusable VPC module remains neutral
  # to the wider IRE architecture.
  recovery_access = {
    vpc_name   = "recovery-access"
    cidr_block = "10.100.0.0/16"

    route_tables = {
      client-vpn-a = {
        group = "client-vpn"
      }

      client-vpn-b = {
        group = "client-vpn"
      }

      admin-a = {
        group = "admin-tools"
      }

      admin-b = {
        group = "admin-tools"
      }
    }

    subnets = {
      client-vpn-a = {
        cidr_block              = "10.100.11.0/24"
        availability_zone_index = 0
        group                   = "client-vpn"
        route_table_key         = "client-vpn-a"
      }

      client-vpn-b = {
        cidr_block              = "10.100.12.0/24"
        availability_zone_index = 1
        group                   = "client-vpn"
        route_table_key         = "client-vpn-b"
      }

      admin-a = {
        cidr_block              = "10.100.21.0/24"
        availability_zone_index = 0
        group                   = "admin-tools"
        route_table_key         = "admin-a"
      }

      admin-b = {
        cidr_block              = "10.100.22.0/24"
        availability_zone_index = 1
        group                   = "admin-tools"
        route_table_key         = "admin-b"
      }
    }
  }

  ##################################################################################################
  # Security Groups
  ##################################################################################################
  security_groups = {
    tiers = {
      management = {
        description = "Management"
      }
    }

    rules = {
      # Administrative ingress is limited to addresses allocated to
      # authenticated Client VPN users.
      management_ssh = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_ipv4   = local.client_vpn.client_cidr_block
      }

      management_ping = {
        ip_protocol = "icmp"
        from_port   = 8
        to_port     = -1
        cidr_ipv4   = local.client_vpn.client_cidr_block
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
  ec2 = {
    ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type = "t3.micro"
  }

  ##################################################################################################
  # Client VPN
  ##################################################################################################
  client_vpn = {
    name = "ire-client-vpn"

    client_cidr_block     = "192.168.0.0/16"
    split_tunnel          = true
    transport_protocol    = "udp"
    vpn_port              = 443
    dns_servers           = []
    session_timeout_hours = 8
    authorize_all_groups  = true
  }
}
