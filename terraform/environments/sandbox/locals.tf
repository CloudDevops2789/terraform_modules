locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to the majority of resources created by the environment. Individual
  # modules may merge additional tags (for example Name) on top of these.
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
  # Static network definition for the Recovery Access tier. This VPC is the
  # administrative entry point into the IRE and is intentionally allocated the
  # 10.213.252.0/24 address space. These values define the environment's network
  # architecture rather than deployment-time configuration.
  recovery_access = {
    vpc_name   = "recovery-access"
    cidr_block = "10.213.252.0/24"

    # 10.213.252.192/26 is reserved for future Recovery Access services.
    route_tables = {
      client-vpn-a = {
        group = "client-vpn"
      }
      client-vpn-b = {
        group = "client-vpn"
      }
      admin-tools-a = {
        group = "admin-tools"
      }
      admin-tools-b = {
        group = "admin-tools"
      }
      endpoints-a = {
        group = "endpoints"
      }
      endpoints-b = {
        group = "endpoints"
      }
      transit-gateway-a = {
        group = "transit-gateway"
      }
      transit-gateway-b = {
        group = "transit-gateway"
      }
    }

    subnets = {
      client-vpn-a = {
        cidr_block              = "10.213.252.0/27"
        availability_zone_index = 0
        group                   = "client-vpn"
        route_table_key         = "client-vpn-a"
      }
      client-vpn-b = {
        cidr_block              = "10.213.252.32/27"
        availability_zone_index = 1
        group                   = "client-vpn"
        route_table_key         = "client-vpn-b"
      }
      admin-tools-a = {
        cidr_block              = "10.213.252.64/27"
        availability_zone_index = 0
        group                   = "admin-tools"
        route_table_key         = "admin-tools-a"
      }
      admin-tools-b = {
        cidr_block              = "10.213.252.96/27"
        availability_zone_index = 1
        group                   = "admin-tools"
        route_table_key         = "admin-tools-b"
      }
      endpoints-a = {
        cidr_block              = "10.213.252.128/28"
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = "10.213.252.144/28"
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = "10.213.252.160/28"
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = "10.213.252.176/28"
        availability_zone_index = 1
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-b"
      }
    }
  }

  ##################################################################################################
  # Core Recovery VPC
  ##################################################################################################
  # Static network definition for the Core Recovery tier. This VPC hosts the
  # recovery tooling and acts as the central routing domain between Recovery
  # Access and Protected Data.
  core_recovery = {
    vpc_name   = "core-recovery"
    cidr_block = "10.213.253.0/24"

    # 10.213.253.224/28 and 10.213.253.240/28 are reserved for
    # distributed Network Firewall endpoints if that design is selected.
    route_tables = {
      recovery-services-a = {
        group = "recovery-services"
      }
      recovery-services-b = {
        group = "recovery-services"
      }
      directory-services-a = {
        group = "directory-services"
      }
      directory-services-b = {
        group = "directory-services"
      }
      endpoints-a = {
        group = "endpoints"
      }
      endpoints-b = {
        group = "endpoints"
      }
      transit-gateway-a = {
        group = "transit-gateway"
      }
      transit-gateway-b = {
        group = "transit-gateway"
      }
    }

    subnets = {
      recovery-services-a = {
        cidr_block              = "10.213.253.0/26"
        availability_zone_index = 0
        group                   = "recovery-services"
        route_table_key         = "recovery-services-a"
      }
      recovery-services-b = {
        cidr_block              = "10.213.253.64/26"
        availability_zone_index = 1
        group                   = "recovery-services"
        route_table_key         = "recovery-services-b"
      }
      directory-services-a = {
        cidr_block              = "10.213.253.128/28"
        availability_zone_index = 0
        group                   = "directory-services"
        route_table_key         = "directory-services-a"
      }
      directory-services-b = {
        cidr_block              = "10.213.253.144/28"
        availability_zone_index = 1
        group                   = "directory-services"
        route_table_key         = "directory-services-b"
      }
      endpoints-a = {
        cidr_block              = "10.213.253.160/28"
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = "10.213.253.176/28"
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = "10.213.253.192/28"
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = "10.213.253.208/28"
        availability_zone_index = 1
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-b"
      }
    }
  }

  ##################################################################################################
  # Protected Data VPC
  ##################################################################################################
  # Static network definition for the Protected Data tier. This VPC contains
  # backup storage and recovery data and is isolated from direct access by the
  # Recovery Access VPC through Transit Gateway routing.
  protected_data = {
    vpc_name   = "protected-data"
    cidr_block = "10.213.254.0/24"

    # 10.213.254.224/27 is reserved for future protected-data services.
    route_tables = {
      protected-workloads-a = {
        group = "protected-workloads"
      }
      protected-workloads-b = {
        group = "protected-workloads"
      }
      ingestion-a = {
        group = "ingestion"
      }
      ingestion-b = {
        group = "ingestion"
      }
      database-a = {
        group = "database"
      }
      database-b = {
        group = "database"
      }
      file-services-a = {
        group = "file-services"
      }
      file-services-b = {
        group = "file-services"
      }
      endpoints-a = {
        group = "endpoints"
      }
      endpoints-b = {
        group = "endpoints"
      }
      transit-gateway-a = {
        group = "transit-gateway"
      }
      transit-gateway-b = {
        group = "transit-gateway"
      }
    }

    subnets = {
      protected-workloads-a = {
        cidr_block              = "10.213.254.0/27"
        availability_zone_index = 0
        group                   = "protected-workloads"
        route_table_key         = "protected-workloads-a"
      }
      protected-workloads-b = {
        cidr_block              = "10.213.254.32/27"
        availability_zone_index = 1
        group                   = "protected-workloads"
        route_table_key         = "protected-workloads-b"
      }
      ingestion-a = {
        cidr_block              = "10.213.254.64/28"
        availability_zone_index = 0
        group                   = "ingestion"
        route_table_key         = "ingestion-a"
      }
      ingestion-b = {
        cidr_block              = "10.213.254.80/28"
        availability_zone_index = 1
        group                   = "ingestion"
        route_table_key         = "ingestion-b"
      }
      database-a = {
        cidr_block              = "10.213.254.96/28"
        availability_zone_index = 0
        group                   = "database"
        route_table_key         = "database-a"
      }
      database-b = {
        cidr_block              = "10.213.254.112/28"
        availability_zone_index = 1
        group                   = "database"
        route_table_key         = "database-b"
      }
      file-services-a = {
        cidr_block              = "10.213.254.128/28"
        availability_zone_index = 0
        group                   = "file-services"
        route_table_key         = "file-services-a"
      }
      file-services-b = {
        cidr_block              = "10.213.254.144/28"
        availability_zone_index = 1
        group                   = "file-services"
        route_table_key         = "file-services-b"
      }
      endpoints-a = {
        cidr_block              = "10.213.254.160/28"
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = "10.213.254.176/28"
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = "10.213.254.192/28"
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = "10.213.254.208/28"
        availability_zone_index = 1
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-b"
      }
    }
  }

  ##################################################################################################
  # Transit Gateway
  ##################################################################################################
  # Static configuration for the Transit Gateway. This defines the gateway
  # itself and the Transit Gateway Route Tables that represent the routing
  # domains within the IRE.
  #
  # NOTE:
  # The map keys (recovery_access, core_recovery, protected_data) are logical
  # Terraform identifiers. These keys are later referenced by the VPC
  # attachments to associate with the correct Transit Gateway Route Table.
  #
  # The 'name' attribute is simply the display name shown in the AWS Console.
  transit_gateway = {

    name = "ire-transit-gateway"

    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    route_tables = {

      recovery_access = {
        name = "Recovery Access Route Table"
      }

      core_recovery = {
        name = "Core Recovery Route Table"
      }

      protected_data = {
        name = "Protected Data Route Table"
      }

    }

  }

  ##################################################################################################
  # Security Groups
  ##################################################################################################
  # Static configuration for the per-tier security groups and their
  # ingress/egress rules. Descriptions and rule protocols/ports are deployment
  # configuration. security_group_id values and any CIDR that references a
  # peer VPC (e.g. module.recovery_access.vpc_cidr) are infrastructure
  # relationships and remain directly in security.tf.
  security_groups = {

    tiers = {
      management = {
        description = "Management"
      }
      core = {
        description = "Core Recovery"
      }
      protected = {
        description = "Protected Data"
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

      # Ports/protocol only. The CIDR for these rules is the peer VPC's CIDR
      # (a relationship) and stays inline in security.tf.
      core_ssh = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
      }

      core_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }

      # Ports/protocol only. The CIDR for this rule is Core Recovery's VPC
      # CIDR (a relationship) and stays inline in security.tf.
      protected_ssh = {
        ip_protocol = "tcp"
        from_port   = 22
        to_port     = 22
      }

      protected_egress = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }

    }
  }

  ##################################################################################################
  # EC2
  ##################################################################################################
  # Static instance configuration shared by the one representative instance
  # deployed per tier: AMI, instance type, and public IP posture. Placement
  # (subnet_id), key material, and security group membership are relationships
  # and remain in compute.tf.
  ec2 = {
    ami                         = var.ami_id # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type               = "t3.micro"
    associate_public_ip_address = false

    # Filter values for the (currently unused) dynamic AMI lookup data source.
    ami_data_source_filter = {
      name_values                = ["al2023-ami-2023*-x86_64"]
      architecture_values        = ["x86_64"]
      virtualization_type_values = ["hvm"]
    }
  }

  ##################################################################################################
  # Client VPN
  ##################################################################################################
  # Static Client VPN configuration: display name, client address pool, and
  # session/transport behaviour. VPC/subnet associations, security group
  # membership, and authorization target CIDRs describe relationships to
  # other resources and remain in client_vpn.tf.
  client_vpn = {
    name                  = "ire-client-vpn"
    client_cidr_block     = "192.168.0.0/16"
    split_tunnel          = true
    transport_protocol    = "udp"
    vpn_port              = 443
    dns_servers           = []
    session_timeout_hours = 8
    authorize_all_groups  = true
  }

  ##################################################################################################
  # Backup
  ##################################################################################################
  # Static AWS Backup configuration: vault/plan/role/selection display names,
  # retention windows, and the daily backup schedule. Vault ARNs, plan IDs,
  # and protected resource references are relationships between the backup
  # modules and remain in backup_vault.tf.
  backup = {
    standard_vault_name = "ire-standard-backup-vault"

    air_gapped_vault_name         = "ire-airgap-backup-vault"
    air_gapped_min_retention_days = 30
    air_gapped_max_retention_days = 365

    plan_name = "ire-backup-plan"

    role_name = "ire-backup-role"

    selection_name = "ire-backup-selection"

    plan_rules = {
      daily = {
        schedule          = "cron(0 5 ? * * *)"
        start_window      = 60
        completion_window = 180

        cold_storage_after = 30
        delete_after       = 365

        # Retention applied to the immutable copy in the air-gapped vault.
        cyber_recovery_delete_after = 365
      }
    }
  }

  ##################################################################################################
  # KMS
  ##################################################################################################
  # Static configuration for the customer managed KMS key used across the
  # sandbox.
  kms = {
    description = "Customer managed KMS key for the IRE sandbox"
    alias       = "ire-sandbox"
  }
}
