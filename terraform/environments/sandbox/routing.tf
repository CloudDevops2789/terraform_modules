##################################################################################################
# Environment-Owned VPC Routing
##################################################################################################
# The VPC module creates no aws_route resources. Route targets can later be
# redirected through Network Firewall endpoints without redesigning the VPCs.

locals {
  sandbox_transit_gateway_routes = {
    recovery_admin_a_to_core = {
      route_table_id         = module.recovery_access.route_table_ids["admin-tools-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    recovery_admin_b_to_core = {
      route_table_id         = module.recovery_access.route_table_ids["admin-tools-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }

    core_services_a_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-a"]
      destination_cidr_block = module.recovery_access.vpc_cidr
    }
    core_services_a_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-a"]
      destination_cidr_block = module.protected_data.vpc_cidr
    }
    core_services_b_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-b"]
      destination_cidr_block = module.recovery_access.vpc_cidr
    }
    core_services_b_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-b"]
      destination_cidr_block = module.protected_data.vpc_cidr
    }

    directory_a_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-a"]
      destination_cidr_block = module.recovery_access.vpc_cidr
    }
    directory_a_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-a"]
      destination_cidr_block = module.protected_data.vpc_cidr
    }
    directory_b_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-b"]
      destination_cidr_block = module.recovery_access.vpc_cidr
    }
    directory_b_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-b"]
      destination_cidr_block = module.protected_data.vpc_cidr
    }

    protected_workloads_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["protected-workloads-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    protected_workloads_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["protected-workloads-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    ingestion_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["ingestion-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    ingestion_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["ingestion-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    database_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["database-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    database_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["database-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    file_services_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["file-services-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
    file_services_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["file-services-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
    }
  }
}

resource "aws_route" "transit_gateway" {
  for_each = local.sandbox_transit_gateway_routes

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  transit_gateway_id     = module.transit_gateway.id

  # Wait for the TGW attachments, associations, and propagations managed
  # inside the module before creating VPC routes toward the gateway.
  depends_on = [module.transit_gateway]
}
