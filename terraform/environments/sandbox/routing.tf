##################################################################################################
# Centralized Network Firewall Routing
##################################################################################################
# Routing ownership is delegated to the reusable network-firewall-routing module.
#
# Approved trust paths:
#
# Recovery Access <-> Core Recovery <-> Protected Data
#
# The spoke VPC route tables continue to send only approved adjacent-VPC destinations to Transit
# Gateway. The spoke Transit Gateway route tables then send those destinations to the Inspection
# VPC attachment. Inside the Inspection VPC, each Transit Gateway attachment subnet forwards traffic
# to the Network Firewall endpoint in the same Availability Zone. Firewall subnet route tables return
# inspected traffic to Transit Gateway.
#
# There is no VPC route or Transit Gateway route between Recovery Access and Protected Data.

locals {
  ################################################################################################
  # Existing spoke VPC routes toward Transit Gateway
  ################################################################################################

  sandbox_spoke_vpc_routes = {
    recovery_admin_a_to_core = {
      route_table_id         = module.recovery_access.route_table_ids["admin-tools-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    recovery_admin_b_to_core = {
      route_table_id         = module.recovery_access.route_table_ids["admin-tools-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    core_services_a_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-a"]
      destination_cidr_block = module.recovery_access.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    core_services_a_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-a"]
      destination_cidr_block = module.protected_data.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    core_services_b_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-b"]
      destination_cidr_block = module.recovery_access.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    core_services_b_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["recovery-services-b"]
      destination_cidr_block = module.protected_data.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    directory_a_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-a"]
      destination_cidr_block = module.recovery_access.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    directory_a_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-a"]
      destination_cidr_block = module.protected_data.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    directory_b_to_recovery = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-b"]
      destination_cidr_block = module.recovery_access.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    directory_b_to_protected = {
      route_table_id         = module.core_recovery.route_table_ids["directory-services-b"]
      destination_cidr_block = module.protected_data.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    protected_workloads_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["protected-workloads-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    protected_workloads_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["protected-workloads-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    ingestion_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["ingestion-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    ingestion_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["ingestion-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    database_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["database-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    database_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["database-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    file_services_a_to_core = {
      route_table_id         = module.protected_data.route_table_ids["file-services-a"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }

    file_services_b_to_core = {
      route_table_id         = module.protected_data.route_table_ids["file-services-b"]
      destination_cidr_block = module.core_recovery.vpc_cidr
      target = {
        transit_gateway_id = module.transit_gateway.id
      }
    }
  }

  ################################################################################################
  # Inspection VPC Availability Zone alignment
  ################################################################################################

  inspection_routing_zones = {
    a = {
      availability_zone = module.inspection_vpc.subnets["transit-gateway-a"].availability_zone
      transit_gateway_route_table_id = (
        module.inspection_vpc.route_table_ids["transit-gateway-a"]
      )
      firewall_route_table_id = (
        module.inspection_vpc.route_table_ids["firewall-a"]
      )
    }

    b = {
      availability_zone = module.inspection_vpc.subnets["transit-gateway-b"].availability_zone
      transit_gateway_route_table_id = (
        module.inspection_vpc.route_table_ids["transit-gateway-b"]
      )
      firewall_route_table_id = (
        module.inspection_vpc.route_table_ids["firewall-b"]
      )
    }
  }

  inspection_spoke_cidrs = {
    recovery_access = module.recovery_access.vpc_cidr
    core_recovery   = module.core_recovery.vpc_cidr
    protected_data  = module.protected_data.vpc_cidr
  }

  inspection_tgw_to_firewall_routes = merge([
    for zone_key, zone in local.inspection_routing_zones : {
      for spoke_key, spoke_cidr in local.inspection_spoke_cidrs :
      "inspection_tgw_${zone_key}_to_${spoke_key}" => {
        route_table_id         = zone.transit_gateway_route_table_id
        destination_cidr_block = spoke_cidr
        target = {
          vpc_endpoint_id = (
            module.network_firewall
            .endpoint_ids_by_availability_zone["inspection"][zone.availability_zone]
          )
        }
      }
    }
  ]...)

  inspection_firewall_to_tgw_routes = merge([
    for zone_key, zone in local.inspection_routing_zones : {
      for spoke_key, spoke_cidr in local.inspection_spoke_cidrs :
      "inspection_firewall_${zone_key}_to_${spoke_key}" => {
        route_table_id         = zone.firewall_route_table_id
        destination_cidr_block = spoke_cidr
        target = {
          transit_gateway_id = module.transit_gateway.id
        }
      }
    }
  ]...)

  sandbox_vpc_routes = merge(
    local.sandbox_spoke_vpc_routes,
    local.inspection_tgw_to_firewall_routes,
    local.inspection_firewall_to_tgw_routes,
  )

  ################################################################################################
  # Spoke TGW route tables -> Inspection VPC attachment
  ################################################################################################

  sandbox_transit_gateway_inspection_routes = {
    recovery_access_to_core = {
      transit_gateway_route_table_id = (
        module.transit_gateway.route_table_ids["recovery_access"]
      )
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_attachment_id = (
        module.transit_gateway.attachment_ids["inspection"]
      )
    }

    core_recovery_to_recovery_access = {
      transit_gateway_route_table_id = (
        module.transit_gateway.route_table_ids["core_recovery"]
      )
      destination_cidr_block = module.recovery_access.vpc_cidr
      transit_gateway_attachment_id = (
        module.transit_gateway.attachment_ids["inspection"]
      )
    }

    core_recovery_to_protected_data = {
      transit_gateway_route_table_id = (
        module.transit_gateway.route_table_ids["core_recovery"]
      )
      destination_cidr_block = module.protected_data.vpc_cidr
      transit_gateway_attachment_id = (
        module.transit_gateway.attachment_ids["inspection"]
      )
    }

    protected_data_to_core = {
      transit_gateway_route_table_id = (
        module.transit_gateway.route_table_ids["protected_data"]
      )
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_attachment_id = (
        module.transit_gateway.attachment_ids["inspection"]
      )
    }
  }
}

# Purpose: Creates the VPC and Transit Gateway routes that steer approved traffic through inspection.
# Change when: Change routes as a complete forward-and-return path to preserve stateful symmetry.
module "network_firewall_routing" {
  source = "../../modules/network-firewall-routing"

  vpc_routes = local.sandbox_vpc_routes
  transit_gateway_routes = (
    local.sandbox_transit_gateway_inspection_routes
  )

  # The Transit Gateway module remains the single owner of attachment
  # associations and propagations.
  route_table_associations                 = {}
  transit_gateway_route_table_associations = {}
  transit_gateway_route_table_propagations = {}
}
