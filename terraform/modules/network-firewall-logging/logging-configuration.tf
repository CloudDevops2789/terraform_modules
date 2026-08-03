##################################################################################################
# AWS Network Firewall Logging Configurations
##################################################################################################
# AWS supports one destination per log type and up to three destinations in total. Logging is emitted
# by the stateful engine for traffic forwarded to it by the firewall policy.
resource "aws_networkfirewall_logging_configuration" "this" {
  for_each                    = local.logging_configurations
  enable_monitoring_dashboard = each.value.enable_monitoring_dashboard
  firewall_arn                = each.value.firewall_arn
  logging_configuration {
    dynamic "log_destination_config" {
      for_each = each.value.destinations
      content {
        log_destination      = log_destination_config.value.log_destination
        log_destination_type = log_destination_config.value.log_destination_type
        log_type             = log_destination_config.value.log_type
      }
    }
  }
}
