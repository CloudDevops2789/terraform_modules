output "directory_id" {
  description = "ID of the AWS Managed Microsoft AD directory created by the module under test."
  value       = module.managed_microsoft_ad.directory_id
}

output "dns_ip_addresses" {
  description = "DNS server IP addresses for the directory created by the module under test."
  value       = module.managed_microsoft_ad.dns_ip_addresses
}

output "directory_name" {
  description = "Fully qualified domain name of the directory created by the module under test."
  value       = module.managed_microsoft_ad.directory_name
}
