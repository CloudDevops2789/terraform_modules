################################################################################
# Persistent Stack Contract Outputs
#
# These outputs form the supported cross-stack contract.
#
# Local Terraform flow:
#   module.<name>.<output>
#       -> output blocks below
#
# Cross-stack flow:
#   output
#       -> ire/<environment>/persistent/terraform.tfstate
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> approved downstream contract input
#
# Current consumers:
#   Platform -> network_firewall_logging_kms_key_arn
#   Recovery -> standard_backup_vault_name
#               air_gapped_backup_vault_arn
#
# Do not bypass this contract by manually copying state values into tfvars.
################################################################################

output "standard_backup_vault_name" {
  description = "Persistent standard AWS Backup vault name, or null when vault management is disabled."
  value       = try(module.backup_standard_vault[0].name, null)
}

output "standard_backup_vault_arn" {
  description = "Persistent standard AWS Backup vault ARN, or null when vault management is disabled."
  value       = try(module.backup_standard_vault[0].arn, null)
}

output "air_gapped_backup_vault_name" {
  description = "Persistent logically air-gapped AWS Backup vault name, or null when vault management is disabled."
  value       = try(module.backup_logically_air_gapped_vault[0].name, null)
}

output "air_gapped_backup_vault_arn" {
  description = "Persistent logically air-gapped AWS Backup vault ARN, or null when vault management is disabled."
  value       = try(module.backup_logically_air_gapped_vault[0].arn, null)
}

output "network_firewall_logging_kms_key_arn" {
  description = "Persistent logging KMS key ARN, or null when customer-managed log encryption is disabled."
  value       = try(module.network_firewall_logging_kms[0].key_arn, null)
}

output "client_vpn_pki_bucket_name" {
  description = "Persistent private S3 bucket used for Client VPN PKI artifacts, or null when disabled."
  value       = try(module.client_vpn_pki_bucket[0].name, null)
}

output "client_vpn_pki_bucket_arn" {
  description = "Persistent private S3 bucket ARN used for Client VPN PKI artifacts, or null when disabled."
  value       = try(module.client_vpn_pki_bucket[0].arn, null)
}

output "client_vpn_pki_kms_key_arn" {
  description = "Persistent KMS key ARN used to encrypt Client VPN PKI artifacts, or null when disabled."
  value       = try(module.client_vpn_pki_kms[0].key_arn, null)
}
