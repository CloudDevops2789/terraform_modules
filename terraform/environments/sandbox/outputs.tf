output "instance_ids" {
  value = module.ec2.instance_ids
}

output "private_ips" {
  value = module.ec2.private_ips
}

output "public_ips" {
  value = module.ec2.public_ips
}


############################################
# Backup Plan Outputs
############################################

output "backup_plan_id" {

  description = "The ID of the Backup Plan."

  value = module.backup_plan.id

}

output "backup_plan_arn" {

  description = "The ARN of the Backup Plan."

  value = module.backup_plan.arn

}

output "backup_plan_version" {

  description = "The version of the Backup Plan."

  value = module.backup_plan.version

}

output "client_vpn_endpoint_id" {
  description = "The ID of the Client VPN endpoint."
  value       = module.client_vpn.id
}
#aws_ec2_client_vpn_endpoint.this.id
##################################################################################################
# Client VPN SAML Identity Provider
##################################################################################################

output "client_vpn_saml_provider_arn" {
  description = "Resolved IAM SAML provider ARN used or managed for Client VPN federation."
  value       = local.resolved_saml_provider_arn
}
