# AWS Network Firewall Logging Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.55, < 7.0`
## Purpose
This module creates AWS Network Firewall logging configurations for existing firewalls. It is intentionally separate from firewall lifecycle management:
```text
network-firewall-rule-group
        ↓
network-firewall-policy
        ↓
network-firewall
        ↓
network-firewall-logging
```
The module owns only `aws_networkfirewall_logging_configuration`. CloudWatch log groups, S3 buckets, Firehose delivery streams, KMS keys, retention policies, bucket policies, and delivery-stream roles remain separate resources owned by the consuming environment or dedicated observability modules.
## Supported log types
- `ALERT`
- `FLOW`
- `TLS`
Each firewall can define at most one destination per log type and at most three destinations total.
TLS logs require a firewall policy configured for TLS inspection.
## Supported destinations
### CloudWatch Logs
```hcl
cloudwatch_logs = {
  log_group_name = aws_cloudwatch_log_group.network_firewall_alert.name
}
```
### Amazon S3
```hcl
s3 = {
  bucket_name = aws_s3_bucket.network_firewall_logs.bucket
  prefix      = "network-firewall/alert"
}
```
### Amazon Data Firehose
```hcl
kinesis_data_firehose = {
  delivery_stream_name = aws_kinesis_firehose_delivery_stream.network_firewall.name
}
```
Every destination object must configure exactly one target type.
## Usage
```hcl
module "network_firewall_logging" {
  source = "../../modules/network-firewall-logging"
  logging_configurations = {
    inspection = {
      firewall_arn                = module.network_firewall.firewall_arns["inspection"]
      enable_monitoring_dashboard = true
      destinations = {
        alert = {
          log_type = "ALERT"
          cloudwatch_logs = {
            log_group_name = aws_cloudwatch_log_group.network_firewall_alert.name
          }
        }
        flow = {
          log_type = "FLOW"
          s3 = {
            bucket_name = aws_s3_bucket.network_firewall_logs.bucket
            prefix      = "flow"
          }
        }
        tls = {
          log_type = "TLS"
          kinesis_data_firehose = {
            delivery_stream_name = aws_kinesis_firehose_delivery_stream.network_firewall_tls.name
          }
        }
      }
    }
  }
}
```
## Monitoring dashboard
Set `enable_monitoring_dashboard = true` to enable the detailed Network Firewall monitoring dashboard for the firewall.
## Permissions
The identity applying this module needs Network Firewall logging permissions and the required log-delivery permissions for the chosen destination. Destination resources and their encryption policies must already exist.
## Operational behavior
Logging applies to traffic processed by the stateful engine. Stateless-only traffic that is passed or dropped before reaching the stateful engine does not produce these logs.
AWS may require a two-step update when changing the destination for an existing log type:
1. Temporarily remove that log type and apply.
2. Add the same log type with the new destination and apply again.
This is an AWS API behavior rather than a Terraform module limitation.
## Module boundaries
This module deliberately does not create:
- CloudWatch log groups
- S3 buckets
- Firehose delivery streams
- KMS keys
- IAM roles or destination policies
- Network Firewalls
- Firewall policies
- Route tables
These resources have separate ownership, retention, encryption, and lifecycle requirements.
## Outputs
- `logging_configurations`
- `logging_configuration_ids`
## Testing
The companion module test creates:
- One isolated VPC and firewall subnet
- One minimal firewall policy
- One Network Firewall endpoint
- Two CloudWatch log groups
- ALERT and FLOW logging destinations
- The detailed monitoring dashboard
AWS Network Firewall is billable while deployed. Destroy the test immediately after lifecycle validation.
