locals {
  ##################################################################################################
  # Recovery Access VPC
  ##################################################################################################
  # Network definition for the Recovery Access tier. The approved VPC and subnet CIDRs are
  # supplied by var.network_config while topology and route-table relationships remain in code.
  recovery_access = {
    vpc_name   = local.resource_names.recovery_access_vpc
    cidr_block = local.network_cidrs.recovery_access

    # Unallocated address space remains reserved for future Recovery Access services.
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
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.client_vpn_a
        availability_zone_index = 0
        group                   = "client-vpn"
        route_table_key         = "client-vpn-a"
      }
      client-vpn-b = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.client_vpn_b
        availability_zone_index = 1
        group                   = "client-vpn"
        route_table_key         = "client-vpn-b"
      }
      admin-tools-a = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.admin_tools_a
        availability_zone_index = 0
        group                   = "admin-tools"
        route_table_key         = "admin-tools-a"
      }
      admin-tools-b = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.admin_tools_b
        availability_zone_index = 1
        group                   = "admin-tools"
        route_table_key         = "admin-tools-b"
      }
      endpoints-a = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.endpoints_a
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.endpoints_b
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.transit_gateway_a
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = var.network_config.vpcs.recovery_access.subnet_cidrs.transit_gateway_b
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
    vpc_name   = local.resource_names.core_recovery_vpc
    cidr_block = local.network_cidrs.core_recovery

    # Unallocated address space remains reserved for future Core Recovery services.
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
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.recovery_services_a
        availability_zone_index = 0
        group                   = "recovery-services"
        route_table_key         = "recovery-services-a"
      }
      recovery-services-b = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.recovery_services_b
        availability_zone_index = 1
        group                   = "recovery-services"
        route_table_key         = "recovery-services-b"
      }
      directory-services-a = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.directory_services_a
        availability_zone_index = 0
        group                   = "directory-services"
        route_table_key         = "directory-services-a"
      }
      directory-services-b = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.directory_services_b
        availability_zone_index = 1
        group                   = "directory-services"
        route_table_key         = "directory-services-b"
      }
      endpoints-a = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.endpoints_a
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.endpoints_b
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.transit_gateway_a
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = var.network_config.vpcs.core_recovery.subnet_cidrs.transit_gateway_b
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
    vpc_name   = local.resource_names.protected_data_vpc
    cidr_block = local.network_cidrs.protected_data

    # Unallocated address space remains reserved for future Protected Data services.
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
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.protected_workloads_a
        availability_zone_index = 0
        group                   = "protected-workloads"
        route_table_key         = "protected-workloads-a"
      }
      protected-workloads-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.protected_workloads_b
        availability_zone_index = 1
        group                   = "protected-workloads"
        route_table_key         = "protected-workloads-b"
      }
      ingestion-a = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.ingestion_a
        availability_zone_index = 0
        group                   = "ingestion"
        route_table_key         = "ingestion-a"
      }
      ingestion-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.ingestion_b
        availability_zone_index = 1
        group                   = "ingestion"
        route_table_key         = "ingestion-b"
      }
      database-a = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.database_a
        availability_zone_index = 0
        group                   = "database"
        route_table_key         = "database-a"
      }
      database-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.database_b
        availability_zone_index = 1
        group                   = "database"
        route_table_key         = "database-b"
      }
      file-services-a = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.file_services_a
        availability_zone_index = 0
        group                   = "file-services"
        route_table_key         = "file-services-a"
      }
      file-services-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.file_services_b
        availability_zone_index = 1
        group                   = "file-services"
        route_table_key         = "file-services-b"
      }
      endpoints-a = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.endpoints_a
        availability_zone_index = 0
        group                   = "endpoints"
        route_table_key         = "endpoints-a"
      }
      endpoints-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.endpoints_b
        availability_zone_index = 1
        group                   = "endpoints"
        route_table_key         = "endpoints-b"
      }
      transit-gateway-a = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.transit_gateway_a
        availability_zone_index = 0
        group                   = "transit-gateway"
        route_table_key         = "transit-gateway-a"
      }
      transit-gateway-b = {
        cidr_block              = var.network_config.vpcs.protected_data.subnet_cidrs.transit_gateway_b
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

    name = local.resource_names.transit_gateway

    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    route_tables = {

      recovery_access = {
        name = local.resource_names.transit_gateway_recovery_access_rt
      }

      core_recovery = {
        name = local.resource_names.transit_gateway_core_recovery_rt
      }

      protected_data = {
        name = local.resource_names.transit_gateway_protected_data_rt
      }

    }

  }
}

####
#Locals to bypass Network firewall
####

locals {
  network_firewall_enabled = var.network_inspection_mode == "firewall"
}
