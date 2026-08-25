##################################################################################################
# Identity Contract Outputs
##################################################################################################

output "managed_ad_enabled" {
  description = "Whether this Identity stack manages an AWS Managed Microsoft AD directory."
  value       = var.managed_ad_enabled
}

output "directory_id" {
  description = "AWS Managed Microsoft AD directory ID, or null when disabled."
  value       = try(module.managed_microsoft_ad[0].directory_id, null)
}

output "access_url" {
  description = "AWS Managed Microsoft AD access URL, or null when disabled."
  value       = try(module.managed_microsoft_ad[0].access_url, null)
}

output "dns_ip_addresses" {
  description = "AWS Managed Microsoft AD DNS server IP addresses, or null when disabled."
  value       = try(module.managed_microsoft_ad[0].dns_ip_addresses, null)
}

output "directory_name" {
  description = "AWS Managed Microsoft AD FQDN, or null when disabled."
  value       = try(module.managed_microsoft_ad[0].directory_name, null)
}

output "security_group_id" {
  description = "AWS-managed directory security group ID, or null when disabled."
  value       = try(module.managed_microsoft_ad[0].security_group_id, null)
}
