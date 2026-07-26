# OUTPUTS are a module's public API - the only values a caller can read.
# Each output is returned as a map keyed by the same instance name the
# caller supplied, so downstream code can say module.ec2.instance_ids["core"]
# instead of relying on ordering.
output "instance_ids" {
  description = "Map of EC2 instance IDs."

  value = {
    for name, instance in aws_instance.this :
    name => instance.id
  }
}

output "instance_arns" {
  description = "Map of EC2 instance ARNs."

  value = {
    for name, instance in aws_instance.this :
    name => instance.arn
  }
}

output "private_ips" {
  description = "Map of private IP addresses."

  value = {
    for name, instance in aws_instance.this :
    name => instance.private_ip
  }
}

# Instances without a public IP return an empty string here rather than
# an error, so this output is safe to reference for private-only fleets.
output "public_ips" {
  description = "Map of public IP addresses."

  value = {
    for name, instance in aws_instance.this :
    name => instance.public_ip
  }
}