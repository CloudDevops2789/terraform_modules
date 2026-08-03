##################################################################################################
# Module Under Test: Network Firewall Logging
##################################################################################################
module "network_firewall_logging" {
  source = "../../../modules/network-firewall-logging"
  logging_configurations = {
    inspection = {
      firewall_arn                = module.network_firewall.firewall_arns["inspection"]
      enable_monitoring_dashboard = true
      destinations = {
        alert = {
          log_type = "ALERT"
          cloudwatch_logs = {
            log_group_name = aws_cloudwatch_log_group.alert.name
          }
        }
        flow = {
          log_type = "FLOW"
          cloudwatch_logs = {
            log_group_name = aws_cloudwatch_log_group.flow.name
          }
        }
      }
    }
  }
}
