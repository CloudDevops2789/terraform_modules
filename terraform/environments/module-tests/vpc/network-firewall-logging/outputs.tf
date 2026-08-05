##################################################################################################
# Validation Outputs
##################################################################################################
output "logging_configurations" {
  description = "Logging configurations created by the module test."
  value       = module.network_firewall_logging.logging_configurations
}
output "firewall_arns" {
  description = "Supporting firewall ARN used by the logging configuration."
  value       = module.network_firewall.firewall_arns
}
output "log_group_names" {
  description = "CloudWatch log groups receiving Network Firewall logs."
  value = {
    alert = aws_cloudwatch_log_group.alert.name
    flow  = aws_cloudwatch_log_group.flow.name
  }
}
