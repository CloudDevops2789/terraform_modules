output "remote_access_enabled" {
  value = var.remote_access_enabled
}

output "client_vpn_endpoint_id" {
  value = try(module.client_vpn[0].id, null)
}

output "client_vpn_dns_name" {
  value = try(module.client_vpn[0].dns_name, null)
}

output "association_subnet_cidrs" {
  description = "CIDRs that downstream resources observe after Client VPN IPv4 SNAT."
  value       = local.association_subnet_cidrs
}
