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

output "public_ips" {
  description = "Map of public IP addresses."

  value = {
    for name, instance in aws_instance.this :
    name => instance.public_ip
  }
}