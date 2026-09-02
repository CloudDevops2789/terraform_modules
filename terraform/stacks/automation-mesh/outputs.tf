output "automation_mesh_enabled" {
  description = "Whether this state owns an Automation Mesh execution node."
  value       = var.automation_mesh_enabled
}

output "instance_id" {
  description = "Execution-node EC2 instance ID, or null when disabled."
  value       = try(module.execution_node.instance_ids["execution-node"], null)
}

output "private_ip" {
  description = "Execution-node private IP, or null when disabled."
  value       = try(module.execution_node.private_ips["execution-node"], null)
}

output "security_group_id" {
  description = "Execution-node security-group ID, or null when disabled."
  value       = try(module.execution_node_security_group.security_group_ids["execution-node"], null)
}

output "subnet_id" {
  description = "Selected existing subnet ID, or null when disabled."
  value       = try(data.aws_subnet.selected[0].id, null)
}
