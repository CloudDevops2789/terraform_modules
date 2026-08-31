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
