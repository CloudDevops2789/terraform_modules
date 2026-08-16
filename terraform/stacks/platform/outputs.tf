##################################################################################################
# Platform Contract Outputs
#
# These outputs form the controlled interface consumed by downstream Identity
# and Recovery stacks. Downstream stacks must not depend on internal module
# implementation details.
##################################################################################################

output "recovery_access_vpc_id" {
  description = "Recovery Access VPC ID."
  value       = module.recovery_access.vpc_id
}

output "core_recovery_vpc_id" {
  description = "Core Recovery VPC ID."
  value       = module.core_recovery.vpc_id
}

output "protected_data_vpc_id" {
  description = "Protected Data VPC ID."
  value       = module.protected_data.vpc_id
}

output "inspection_vpc_id" {
  description = "Inspection VPC ID."
  value       = module.inspection_vpc.vpc_id
}

output "recovery_access_subnet_ids" {
  description = "Recovery Access subnet IDs keyed by logical subnet name."
  value       = module.recovery_access.subnet_ids
}

output "core_recovery_subnet_ids" {
  description = "Core Recovery subnet IDs keyed by logical subnet name."
  value       = module.core_recovery.subnet_ids
}

output "core_recovery_subnet_ids_by_group" {
  description = "Core Recovery subnet IDs grouped by subnet function."
  value       = module.core_recovery.subnet_ids_by_group
}

output "protected_data_subnet_ids" {
  description = "Protected Data subnet IDs keyed by logical subnet name."
  value       = module.protected_data.subnet_ids
}

output "security_group_ids" {
  description = "Platform security group IDs keyed by logical security-group name."
  value       = module.security_group.security_group_ids
}

output "transit_gateway_id" {
  description = "IRE Transit Gateway ID."
  value       = module.transit_gateway.id
}

output "ssm_instance_profile_name" {
  description = "EC2 instance profile used by SSM-managed recovery compute, or null when externally managed or disabled."
  value       = local.effective_ssm_instance_profile_name
}

output "client_vpn_endpoint_id" {
  description = "AWS Client VPN endpoint ID, or null when Client VPN is disabled."
  value       = try(module.client_vpn[0].id, null)
}

output "client_vpn_saml_provider_arn" {
  description = "Resolved IAM SAML provider ARN used by Client VPN federation."
  value       = local.resolved_saml_provider_arn
}

output "directory_services_subnet_ids" {
  description = "Core Recovery subnet IDs reserved for directory services."
  value       = module.core_recovery.subnet_ids_by_group["directory-services"]
}
