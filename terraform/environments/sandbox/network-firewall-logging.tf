##################################################################################################
# Network Firewall CloudWatch Logging
##################################################################################################
# ALERT and FLOW logs are written to dedicated CloudWatch log groups encrypted by a customer-managed
# KMS key. The logging key is separate from the general Sandbox key so that the CloudWatch Logs
# service permission and encryption-context scope do not broaden the general-purpose key policy.
#
# TLS logging is intentionally omitted because the Sandbox firewall policy does not perform TLS
# decryption. The detailed monitoring dashboard also remains disabled to avoid automatic log-query
# charges during this infrastructure-validation stage.

data "aws_partition" "network_firewall_logging" {}

data "aws_caller_identity" "network_firewall_logging" {}

locals {
  network_firewall_logging = {
    kms_alias       = local.resource_names.network_firewall_logging_kms_alias
    kms_description = "Customer managed KMS key for encrypted AWS Network Firewall CloudWatch log groups in the ${var.naming.project_display_name} ${var.naming.environment_display_name}"

    retention_in_days = 30

    log_groups = {
      alert = {
        name     = "${local.resource_names.network_firewall_log_group_prefix}/alert"
        log_type = "ALERT"
      }

      flow = {
        name     = "${local.resource_names.network_firewall_log_group_prefix}/flow"
        log_type = "FLOW"
      }
    }
  }
}

##################################################################################################
# CloudWatch Logs KMS Policy
##################################################################################################
# CloudWatch Logs uses the regional service principal and supplies the log-group ARN in the KMS
# encryption context. The condition limits this key to the two Network Firewall log groups below.

data "aws_iam_policy_document" "network_firewall_logging_kms" {
  statement {
    sid    = "AllowCloudWatchLogsEncryption"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = ["*"]

    principals {
      type = "Service"

      identifiers = [
        "logs.${var.aws_region}.${data.aws_partition.network_firewall_logging.dns_suffix}"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:${data.aws_partition.network_firewall_logging.partition}:logs:${var.aws_region}:${data.aws_caller_identity.network_firewall_logging.account_id}:log-group:${local.resource_names.network_firewall_log_group_prefix}/*"
      ]
    }
  }
}

##################################################################################################
# Dedicated Logging KMS Key
##################################################################################################

module "network_firewall_logging_kms" {
  source = "../../modules/kms"

  description = local.network_firewall_logging.kms_description
  alias       = local.network_firewall_logging.kms_alias

  additional_policy_documents = [
    data.aws_iam_policy_document.network_firewall_logging_kms.json
  ]

  tags = merge(
    local.org_tags,
    {
      org_service_name = "network-firewall-logging"
    }
  )
}

##################################################################################################
# Encrypted CloudWatch Log Groups
##################################################################################################

resource "aws_cloudwatch_log_group" "network_firewall" {
  for_each = (
    local.network_firewall_enabled
    ? local.network_firewall_logging.log_groups
    : {}
  )

  name              = each.value.name
  retention_in_days = local.network_firewall_logging.retention_in_days
  kms_key_id        = module.network_firewall_logging_kms.key_arn

  tags = merge(
    local.org_tags,
    {
      org_service_name = "network-firewall-logging"
      org_log_type     = lower(each.value.log_type)
    }
  )
}

##################################################################################################
# Network Firewall Logging Configuration
##################################################################################################

# Purpose: Sends Network Firewall flow and alert logs to the configured encrypted destinations.
# Change when: Change destinations, retention, or encryption only through logging requirements.
module "network_firewall_logging" {
  source = "../../modules/network-firewall-logging"

  logging_configurations = local.network_firewall_enabled ? {
    inspection = {
      firewall_arn                = module.network_firewall.firewall_arns["inspection"]
      enable_monitoring_dashboard = false

      destinations = {
        for destination_key, destination in local.network_firewall_logging.log_groups :
        destination_key => {
          log_type = destination.log_type

          cloudwatch_logs = {
            log_group_name = aws_cloudwatch_log_group.network_firewall[destination_key].name
          }
        }
      }
    }
  } : {}
}

##################################################################################################
# Logging Outputs
##################################################################################################

output "network_firewall_log_group_names" {
  description = "Encrypted CloudWatch log group names keyed by Network Firewall log type."
  value = {
    for key, log_group in aws_cloudwatch_log_group.network_firewall :
    key => log_group.name
  }
}

output "network_firewall_logging_kms_key_arn" {
  description = "ARN of the customer-managed KMS key used for Network Firewall log encryption."
  value       = module.network_firewall_logging_kms.key_arn
}

output "network_firewall_logging_configuration_ids" {
  description = "Network Firewall logging configuration IDs keyed by logical identifier."
  value       = module.network_firewall_logging.logging_configuration_ids
}
