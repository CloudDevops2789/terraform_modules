locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to the majority of resources created by the environment. Individual
  # modules may merge additional tags (for example Name) on top of these.
  default_tags = {
    Environment = "Sandbox"
    Project     = "AWS-IRE"
    Owner       = "CloudEngineering"
    ManagedBy   = "Terraform"
  }

  ##################################################################################################
  # Recovery Access VPC
  ##################################################################################################
  # Static network definition for the Recovery Access tier. This VPC is the
  # administrative entry point into the IRE and is intentionally allocated the
  # 10.100.0.0/16 address space. These values define the environment's network
  # architecture rather than deployment-time configuration.
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
  # Core Recovery VPC
  ##################################################################################################
  # Static network definition for the Core Recovery tier. This VPC hosts the
  # recovery tooling and acts as the central routing domain between Recovery
  # Access and Protected Data.
  core_recovery = {
    vpc_name                = "core-recovery"
    cidr_block              = "10.101.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.101.11.0/24"
      private-b = "10.101.12.0/24"
    }
  }

  ##################################################################################################
  # Protected Data VPC
  ##################################################################################################
  # Static network definition for the Protected Data tier. This VPC contains
  # backup storage and recovery data and is isolated from direct access by the
  # Recovery Access VPC through Transit Gateway routing.
  protected_data = {
    vpc_name                = "protected-data"
    cidr_block              = "10.102.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.102.11.0/24"
      private-b = "10.102.12.0/24"
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
    ami                         = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
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
