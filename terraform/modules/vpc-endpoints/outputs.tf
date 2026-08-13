##################################################################################################
# VPC Endpoint Module Outputs
##################################################################################################

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs keyed by logical endpoint key."
  value = {
    for key, endpoint in aws_vpc_endpoint.interface :
    key => endpoint.id
  }
}

output "interface_endpoint_arns" {
  description = "Interface endpoint ARNs keyed by logical endpoint key."
  value = {
    for key, endpoint in aws_vpc_endpoint.interface :
    key => endpoint.arn
  }
}

output "gateway_endpoint_ids" {
  description = "Gateway endpoint IDs keyed by logical endpoint key."
  value = {
    for key, endpoint in aws_vpc_endpoint.gateway :
    key => endpoint.id
  }
}

output "gateway_endpoint_arns" {
  description = "Gateway endpoint ARNs keyed by logical endpoint key."
  value = {
    for key, endpoint in aws_vpc_endpoint.gateway :
    key => endpoint.arn
  }
}

output "interface_endpoint_dns_entries" {
  description = "DNS entries returned for each Interface VPC endpoint."
  value = {
    for key, endpoint in aws_vpc_endpoint.interface :
    key => endpoint.dns_entry
  }
}

output "interface_endpoint_network_interface_ids" {
  description = "Elastic network interface IDs created for each Interface VPC endpoint."
  value = {
    for key, endpoint in aws_vpc_endpoint.interface :
    key => endpoint.network_interface_ids
  }
}

output "gateway_endpoint_prefix_list_ids" {
  description = "AWS-managed prefix-list IDs associated with Gateway VPC endpoints."
  value = {
    for key, endpoint in aws_vpc_endpoint.gateway :
    key => endpoint.prefix_list_id
  }
}
