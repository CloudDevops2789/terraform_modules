locals {
  ##################################################################################################
  # Logging Configuration Normalization
  ##################################################################################################
  # Caller-facing destination objects are converted into the exact key/value maps expected by the
  # AWS Network Firewall API while preserving stable logical destination keys.
  logging_configurations = {
    for configuration_key, configuration in var.logging_configurations :
    configuration_key => {
      firewall_arn                = configuration.firewall_arn
      enable_monitoring_dashboard = configuration.enable_monitoring_dashboard
      destinations = {
        for destination_key, destination in configuration.destinations :
        destination_key => {
          log_type = destination.log_type
          log_destination_type = (
            destination.cloudwatch_logs != null ? "CloudWatchLogs" :
            destination.s3 != null ? "S3" :
            "KinesisDataFirehose"
          )
          log_destination = (
            destination.cloudwatch_logs != null ?
            tomap({
              logGroup = destination.cloudwatch_logs.log_group_name
            }) :
            destination.s3 != null ?
            tomap(merge(
              {
                bucketName = destination.s3.bucket_name
              },
              destination.s3.prefix == null ? {} : {
                prefix = destination.s3.prefix
              }
            )) :
            tomap({
              deliveryStream = destination.kinesis_data_firehose.delivery_stream_name
            })
          )
        }
      }
    }
  }
}
