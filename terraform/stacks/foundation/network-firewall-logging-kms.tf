##################################################################################################
# Persistent Network Firewall Logging KMS Key
##################################################################################################

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

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
        "logs.${var.aws_region}.${data.aws_partition.current.dns_suffix}"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.network_firewall_log_group_prefix}/*"
      ]
    }
  }
}

module "network_firewall_logging_kms" {
  source = "../../modules/kms"

  description = local.network_firewall_logging_kms_description
  alias       = local.network_firewall_logging_kms_alias

  # Never bootstrap a temporary AWX STS session into the key policy.
  bootstrap_current_caller = false
  key_administrators       = var.kms_key_administrators

  additional_policy_documents = [
    data.aws_iam_policy_document.network_firewall_logging_kms.json
  ]

  tags = merge(
    local.org_tags,
    {
      "fv:service_name" = "network-firewall-logging"
    }
  )
}
