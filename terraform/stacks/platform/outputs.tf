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

output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID, or null when Client VPN is disabled."
  value       = try(module.client_vpn[0].id, null)
}

output "client_vpn_saml_provider_arn" {
  description = "Resolved IAM SAML provider ARN used by Client VPN."
  value       = local.resolved_saml_provider_arn
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
