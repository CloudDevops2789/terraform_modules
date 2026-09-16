##################################################################################################
# Network Flow Log Outputs
##################################################################################################

output "vpc_flow_log_ids" {
  description = "VPC Flow Log IDs keyed by Platform VPC key."

  value = {
    for vpc_key, flow_log in aws_flow_log.vpc :
    vpc_key => flow_log.id
  }
}

output "transit_gateway_flow_log_id" {
  description = "Transit Gateway Flow Log ID, or null when TGW flow logging is disabled."

  value = try(
    aws_flow_log.transit_gateway[0].id,
    null
  )
}

output "network_flow_log_group_names" {
  description = "CloudWatch log-group names used for Platform network Flow Logs."

  value = {
    for key, log_group in aws_cloudwatch_log_group.network_flow_logs :
    key => log_group.name
  }
}
