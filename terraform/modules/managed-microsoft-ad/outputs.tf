############################################################
# AWS Managed Microsoft AD Outputs
############################################################

output "directory_id" {
  description = "Unique identifier of the AWS Managed Microsoft AD directory."
  value       = aws_directory_service_directory.this.id
}

output "access_url" {
  description = "Access URL assigned to the directory."
  value       = aws_directory_service_directory.this.access_url
}

output "dns_ip_addresses" {
  description = "DNS server IP addresses for the managed directory."
  value       = aws_directory_service_directory.this.dns_ip_addresses
}

output "directory_name" {
  description = "Fully qualified domain name (FQDN) of the directory."
  value       = aws_directory_service_directory.this.name
}

output "security_group_id" {
  description = "Security group associated with the managed directory."
  value       = aws_directory_service_directory.this.security_group_id
}