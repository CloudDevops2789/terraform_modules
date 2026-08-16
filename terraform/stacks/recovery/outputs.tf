##################################################################################################
# Recovery Outputs
##################################################################################################

output "instance_ids" {
  description = "Recovery EC2 instance IDs keyed by logical workload name."
  value       = module.ec2.instance_ids
}

output "instance_arns" {
  description = "Recovery EC2 instance ARNs keyed by logical workload name."
  value       = module.ec2.instance_arns
}

output "private_ips" {
  description = "Recovery EC2 private IP addresses keyed by logical workload name."
  value       = module.ec2.private_ips
}

output "public_ips" {
  description = "Recovery EC2 public IP addresses keyed by logical workload name."
  value       = module.ec2.public_ips
}

output "backup_plan_id" {
  description = "Recovery Backup plan ID, or null when backup integration is disabled."
  value       = try(module.backup_plan[0].id, null)
}

output "backup_plan_arn" {
  description = "Recovery Backup plan ARN, or null when backup integration is disabled."
  value       = try(module.backup_plan[0].arn, null)
}

output "backup_plan_version" {
  description = "Recovery Backup plan version, or null when backup integration is disabled."
  value       = try(module.backup_plan[0].version, null)
}
