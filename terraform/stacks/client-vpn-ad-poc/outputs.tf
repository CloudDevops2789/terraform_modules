output "directory_id" {
  description = "AWS Managed Microsoft AD directory identifier used by the bootstrap job."
  value       = module.managed_microsoft_ad.directory_id
}

output "directory_name" {
  description = "AWS Managed Microsoft AD DNS name."
  value       = module.managed_microsoft_ad.directory_name
}

output "directory_dns_ip_addresses" {
  description = "DNS addresses assigned to the managed directory."
  value       = module.managed_microsoft_ad.dns_ip_addresses
}

output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID, or null before the VPN stage is enabled."
  value       = try(module.client_vpn[0].id, null)
}

output "client_vpn_dns_name" {
  description = "Client VPN DNS name, or null before the VPN stage is enabled."
  value       = try(module.client_vpn[0].dns_name, null)
}

output "windows_instance_id" {
  description = "Private Windows validation instance ID."
  value       = module.ec2.instance_ids["windows-test"]
}

output "windows_private_ip" {
  description = "Private address reached after Client VPN authentication."
  value       = module.ec2.private_ips["windows-test"]
}
