##################################################################################################
# Generic Platform Contract
##################################################################################################

output "vpc_ids" {
  description = "VPC IDs keyed by caller-defined logical VPC key."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.vpc_id
  }
}

output "vpc_cidrs" {
  description = "VPC CIDRs keyed by caller-defined logical VPC key."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.vpc_cidr
  }
}

output "subnet_ids" {
  description = "Subnet IDs keyed first by VPC key and then subnet key."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.subnet_ids
  }
}

output "subnet_ids_by_group" {
  description = "Subnet IDs grouped by caller-defined function inside each VPC."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.subnet_ids_by_group
  }
}

output "subnet_cidrs_by_group" {
  description = "Subnet IPv4 CIDRs grouped by caller-defined function inside each VPC."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => {
      for group in distinct([
        for subnet in values(vpc.subnets) : subnet.group
      ]) :
      group => [
        for subnet_key in sort(keys(vpc.subnets)) :
        vpc.subnets[subnet_key].cidr_block
        if vpc.subnets[subnet_key].group == group
      ]
    }
  }
}

output "route_table_ids" {
  description = "Route-table IDs keyed first by VPC key and then route-table key."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.route_table_ids
  }
}

output "route_table_ids_by_group" {
  description = "Route-table IDs grouped by function inside each VPC."

  value = {
    for vpc_key, vpc in module.vpc :
    vpc_key => vpc.route_table_ids_by_group
  }
}

output "security_group_ids" {
  description = "Security-group IDs keyed by caller-defined logical name."
  value       = module.security_group.security_group_ids
}

output "transit_gateway_id" {
  description = "IRE Transit Gateway ID."
  value       = module.transit_gateway.id
}

output "transit_gateway_attachment_ids" {
  description = "Transit Gateway attachment IDs keyed by VPC key."
  value       = module.transit_gateway.attachment_ids
}

output "transit_gateway_route_table_ids" {
  description = "Transit Gateway route-table IDs keyed by VPC key."
  value       = module.transit_gateway.route_table_ids
}

output "ssm_instance_profile_name" {
  description = "EC2 instance profile used by SSM-managed recovery compute."
  value       = local.effective_ssm_instance_profile_name
}

output "platform_contract" {
  description = "Topology-agnostic downstream Platform contract."

  value = {
    vpc_ids = {
      for vpc_key, vpc in module.vpc :
      vpc_key => vpc.vpc_id
    }

    vpc_cidrs = {
      for vpc_key, vpc in module.vpc :
      vpc_key => vpc.vpc_cidr
    }

    subnet_ids = {
      for vpc_key, vpc in module.vpc :
      vpc_key => vpc.subnet_ids
    }

    subnet_ids_by_group = {
      for vpc_key, vpc in module.vpc :
      vpc_key => vpc.subnet_ids_by_group
    }

    subnet_cidrs_by_group = {
      for vpc_key, vpc in module.vpc :
      vpc_key => {
        for group in distinct([
          for subnet in values(vpc.subnets) : subnet.group
        ]) :
        group => [
          for subnet_key in sort(keys(vpc.subnets)) :
          vpc.subnets[subnet_key].cidr_block
          if vpc.subnets[subnet_key].group == group
        ]
      }
    }

    route_table_ids = {
      for vpc_key, vpc in module.vpc :
      vpc_key => vpc.route_table_ids
    }

    security_group_ids = module.security_group.security_group_ids

    ssm_instance_profile_name = (
      local.effective_ssm_instance_profile_name
    )
  }
}


##################################################################################################
# Inspection Topology Contract
##################################################################################################
#
# Purpose
# -------
# Exposes only the Platform-owned topology required by the independently
# lifecycle-managed Inspection stack.
#
# Ownership boundary
# ------------------
# Platform continues to own:
#   - Inspection VPC and subnets
#   - Transit Gateway
#   - Transit Gateway VPC attachments
#   - Transit Gateway route tables
#
# Inspection consumes this contract to own:
#   - AWS Network Firewall
#   - Firewall policy and rule groups
#   - Firewall logging
#   - Routes whose next hop depends on Network Firewall endpoints
#
# The contract deliberately avoids exposing complete Platform implementation
# details. Downstream stacks must not reconstruct identifiers by AWS resource
# names or query Platform resources independently.
##################################################################################################

output "inspection_contract" {
  description = "Platform-owned topology contract consumed by the Inspection lifecycle stack."

  value = {
    transit_gateway_id = module.transit_gateway.id

    account_cidr_block = var.network_config.account_cidr_block

    # Approved directional connectivity required by Inspection to construct
    # TGW routes through the Inspection attachment. Platform retains ownership
    # of the complete network_config and VPC route-table placement policy.
    connectivity = {
      for edge_key, edge in var.network_config.connectivity :
      edge_key => {
        source_vpc_key      = edge.source_vpc_key
        destination_vpc_key = edge.destination_vpc_key
      }
    }

    inspection_vpc = (
      local.inspection_vpc_key == null
      ? null
      : {
        key = local.inspection_vpc_key

        vpc_id = module.vpc[
          local.inspection_vpc_key
        ].vpc_id

        cidr_block = module.vpc[
          local.inspection_vpc_key
        ].vpc_cidr

        transit_gateway_attachment_id = try(
          module.transit_gateway.attachment_ids[
            local.inspection_vpc_key
          ],
          null
        )

        firewall_subnets_by_az = {
          for subnet_key, subnet in module.vpc[
            local.inspection_vpc_key
          ].subnets :

          subnet.availability_zone => {
            subnet_id      = subnet.id
            cidr_block     = subnet.cidr_block
            route_table_id = subnet.route_table_id
          }

          if subnet.group == local.inspection_firewall_subnet_group
        }

        transit_gateway_subnets_by_az = {
          for subnet_key, subnet in module.vpc[
            local.inspection_vpc_key
          ].subnets :

          subnet.availability_zone => {
            subnet_id      = subnet.id
            cidr_block     = subnet.cidr_block
            route_table_id = subnet.route_table_id
          }

          if subnet.group == local.inspection_transit_gateway_subnet_group
        }
      }
    )

    spoke_vpcs = {
      for vpc_key, vpc in local.transit_gateway_vpcs :

      vpc_key => {
        vpc_id = module.vpc[
          vpc_key
        ].vpc_id

        cidr_block = module.vpc[
          vpc_key
        ].vpc_cidr

        transit_gateway_attachment_id = module.transit_gateway.attachment_ids[
          vpc_key
        ]

        transit_gateway_route_table_id = module.transit_gateway.route_table_ids[
          vpc_key
        ]
      }

      if vpc_key != local.inspection_vpc_key
    }
  }
}

##################################################################################################
# S3 Gateway Endpoints
##################################################################################################

output "s3_gateway_endpoint_ids" {
  description = "S3 Gateway VPC endpoint IDs keyed by Platform VPC key."

  value = {
    for vpc_key, endpoints in module.s3_gateway_endpoints :
    vpc_key => endpoints.gateway_endpoint_ids["s3"]
  }
}

output "s3_gateway_endpoint_prefix_list_ids" {
  description = "AWS-managed S3 prefix-list IDs keyed by Platform VPC key."

  value = {
    for vpc_key, endpoints in module.s3_gateway_endpoints :
    vpc_key => endpoints.gateway_endpoint_prefix_list_ids["s3"]
  }
}
