##################################################################################################
# Logging Configuration Outputs
##################################################################################################
output "logging_configurations" {
  description = "Network Firewall logging configuration attributes keyed by logical identifiers."
  value = {
    for key, configuration in aws_networkfirewall_logging_configuration.this : key => {
      id                          = configuration.id
      firewall_arn                = configuration.firewall_arn
      enable_monitoring_dashboard = configuration.enable_monitoring_dashboard
      logging_configuration       = configuration.logging_configuration
    }
  }
}
output "logging_configuration_ids" {
  description = "Network Firewall logging configuration IDs keyed by logical identifiers."
  value = {
    for key, configuration in aws_networkfirewall_logging_configuration.this :
    key => configuration.id
  }
}
