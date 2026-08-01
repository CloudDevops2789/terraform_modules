output "security_group_ids" {
  description = "Security group IDs created by the module under test."
  value       = module.security_group.security_group_ids
}
