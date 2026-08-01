output "instance_ids" {
  description = "Map of EC2 instance IDs created by the module under test."
  value       = module.ec2.instance_ids
}

output "private_ips" {
  description = "Map of private IP addresses created by the module under test."
  value       = module.ec2.private_ips
}
