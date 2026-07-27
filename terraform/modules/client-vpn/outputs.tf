############################################
# Client VPN Endpoint
############################################

# The ID of the Client VPN endpoint.
output "id" {
  description = "The ID of the Client VPN endpoint."

  value = aws_ec2_client_vpn_endpoint.this.id
}

# The ARN of the Client VPN endpoint.
output "arn" {
  description = "The ARN of the Client VPN endpoint."

  value = aws_ec2_client_vpn_endpoint.this.arn
}

# The DNS name clients use to establish a VPN connection.
output "dns_name" {
  description = "The DNS name of the Client VPN endpoint."

  value = aws_ec2_client_vpn_endpoint.this.dns_name
}

############################################
# Network Associations
############################################

# IDs of the Client VPN network associations.
output "network_association_ids" {
  description = "Map of Client VPN network association IDs."

  value = {
    for key, association in aws_ec2_client_vpn_network_association.this :
    key => association.id
  }
}

############################################
# Authorization Rules
############################################

# IDs of the Client VPN authorization rules.
output "authorization_rule_ids" {
  description = "Map of Client VPN authorization rule IDs."

  value = {
    for key, rule in aws_ec2_client_vpn_authorization_rule.this :
    key => rule.id
  }
}

############################################
# Routes
############################################

# IDs of the Client VPN routes.
output "route_ids" {
  description = "Map of Client VPN route IDs."

  value = {
    for key, route in aws_ec2_client_vpn_route.this :
    key => route.id
  }
}

############################################
# CloudWatch Logging
############################################

# CloudWatch Log Group name.
output "log_group_name" {
  description = "CloudWatch Log Group used for Client VPN logging."

  value = aws_cloudwatch_log_group.this.name
}

# CloudWatch Log Stream name.
output "log_stream_name" {
  description = "CloudWatch Log Stream used for Client VPN logging."

  value = aws_cloudwatch_log_stream.this.name
}