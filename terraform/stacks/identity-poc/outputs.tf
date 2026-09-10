################################################################################
# Identity PoC Outputs
################################################################################

output "directory_id" {
  description = "Managed Microsoft AD directory ID."
  value       = module.managed_microsoft_ad.directory_id
}

output "directory_name" {
  description = "Managed Microsoft AD directory DNS name."
  value       = module.managed_microsoft_ad.directory_name
}

output "identity_contract" {
  description = "Small workflow contract for the Managed AD bootstrap test."

  value = {
    managed_ad_enabled = true
    directory_id       = module.managed_microsoft_ad.directory_id
    directory_name     = module.managed_microsoft_ad.directory_name
  }
}
