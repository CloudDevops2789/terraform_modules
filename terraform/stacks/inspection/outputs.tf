##################################################################################################
# Inspection Service Contract
##################################################################################################
#
# These outputs become authoritative only after Network Firewall resource
# ownership has been migrated from Platform into the Inspection state.
##################################################################################################

output "network_firewall_arn" {
  description = "ARN of the centralized AWS Network Firewall."

  value = (
    module.network_firewall
    .firewall_arns["inspection"]
  )
}

output "network_firewall_endpoint_ids_by_availability_zone" {
  description = "Network Firewall endpoint IDs keyed by Availability Zone."

  value = (
    module.network_firewall
    .endpoint_ids_by_availability_zone["inspection"]
  )
}

output "network_firewall_log_group_names" {
  description = "CloudWatch log group names keyed by Network Firewall log type."

  value = {
    for key, log_group in aws_cloudwatch_log_group.network_firewall :
    key => log_group.name
  }
}

output "network_firewall_logging_kms_key_arn" {
  description = "Persistent-owned KMS key used for firewall logging, or null when logging/default encryption is used."

  value = (
    var.network_firewall_logging_enabled
    ? local.network_firewall_logging_kms_key_arn
    : null
  )
}

output "network_firewall_logging_configuration_ids" {
  description = "Network Firewall logging configuration IDs keyed by logical identifier."

  value = (
    module.network_firewall_logging
    .logging_configuration_ids
  )
}
