output "client_vpn_endpoint_id" {
  description = "ID of the Client VPN endpoint created by the module under test."
  value       = module.client_vpn.id
}

output "client_vpn_dns_name" {
  description = "DNS name of the Client VPN endpoint created by the module under test."
  value       = module.client_vpn.dns_name
}
