output "key_id" {
  description = "ID of the KMS key created by the module under test."
  value       = module.kms.key_id
}

output "key_arn" {
  description = "ARN of the KMS key created by the module under test."
  value       = module.kms.key_arn
}

output "alias_name" {
  description = "Alias name created by the module under test."
  value       = module.kms.alias_name
}
