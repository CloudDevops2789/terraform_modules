##################################################################################################
# Network Firewall Logging Configurations
##################################################################################################
# The logical map key provides a stable Terraform resource address. Each configuration owns the
# logging settings for exactly one firewall and can define one destination for each supported log
# type: ALERT, FLOW, and TLS.
variable "logging_configurations" {
  description = "AWS Network Firewall logging configurations keyed by stable logical identifiers."
  type = map(object({
    firewall_arn                = string
    enable_monitoring_dashboard = optional(bool, false)
    destinations = map(object({
      log_type = string
      cloudwatch_logs = optional(object({
        log_group_name = string
      }))
      s3 = optional(object({
        bucket_name = string
        prefix      = optional(string)
      }))
      kinesis_data_firehose = optional(object({
        delivery_stream_name = string
      }))
    }))
  }))
  default = {}
  validation {
    condition = alltrue([
      for configuration in values(var.logging_configurations) :
      can(regex("^arn:[^:]+:network-firewall:[^:]+:[0-9]{12}:firewall/.+$", configuration.firewall_arn))
    ])
    error_message = "Every firewall_arn must be a valid AWS Network Firewall ARN."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.logging_configurations) :
      length(configuration.destinations) >= 1 &&
      length(configuration.destinations) <= 3
    ])
    error_message = "Every logging configuration must define between one and three destinations."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.logging_configurations) : [
        for destination in values(configuration.destinations) :
        contains(["ALERT", "FLOW", "TLS"], destination.log_type)
      ]
    ]))
    error_message = "log_type must be ALERT, FLOW, or TLS."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.logging_configurations) :
      length([
        for destination in values(configuration.destinations) :
        destination.log_type
        ]) == length(distinct([
          for destination in values(configuration.destinations) :
          destination.log_type
      ]))
    ])
    error_message = "Each logging configuration can define at most one destination for each log type."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.logging_configurations) : [
        for destination in values(configuration.destinations) :
        (destination.cloudwatch_logs != null ? 1 : 0) +
        (destination.s3 != null ? 1 : 0) +
        (destination.kinesis_data_firehose != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Every destination must define exactly one target: cloudwatch_logs, s3, or kinesis_data_firehose."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.logging_configurations) : [
        for destination in values(configuration.destinations) :
        destination.cloudwatch_logs == null ? true : length(destination.cloudwatch_logs.log_group_name) >= 1
      ]
    ]))
    error_message = "CloudWatch Logs destinations require a nonempty log_group_name."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.logging_configurations) : [
        for destination in values(configuration.destinations) :
        destination.s3 == null ? true : length(destination.s3.bucket_name) >= 3
      ]
    ]))
    error_message = "S3 destinations require a bucket_name containing at least three characters."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.logging_configurations) : [
        for destination in values(configuration.destinations) :
        destination.kinesis_data_firehose == null ? true : length(destination.kinesis_data_firehose.delivery_stream_name) >= 1
      ]
    ]))
    error_message = "Firehose destinations require a nonempty delivery_stream_name."
  }
}
