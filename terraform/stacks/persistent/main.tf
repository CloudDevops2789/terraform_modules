################################################################################
# Persistent AWS Backup Resources
#
# Lifecycle ownership:
#   These vaults are long-lived recovery assets owned only by the Persistent
#   Terraform state. Disposable Recovery-stack destruction must never own or
#   implicitly delete them.
#
# Input flow:
#   terraform/environments/<environment>/config/persistent.tfvars
#       -> variables.tf
#       -> locals.tf for derived names/tags
#       -> module blocks below
#
# Downstream dependency flow:
#   module outputs
#       -> outputs.tf
#       -> Persistent Terraform state
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> Recovery stack persistent_resources input
################################################################################

module "backup_standard_vault" {
  count = var.backup_vaults_enabled ? 1 : 0

  source = "../../modules/backup-standard-vault"

  name = local.standard_backup_vault_name

  # Retained recovery points must never be implicitly deleted by Terraform.
  force_destroy = false

  tags = local.org_tags
}

module "backup_logically_air_gapped_vault" {
  count = var.backup_vaults_enabled ? 1 : 0

  source = "../../modules/backup-logically-air-gapped-vault"

  name = local.air_gapped_backup_vault_name

  min_retention_days = var.air_gapped_min_retention_days
  max_retention_days = var.air_gapped_max_retention_days

  tags = local.org_tags
}


################################################################################
# Optional Network Firewall Logging KMS Key
#
# Purpose:
#   Provides the long-lived customer-managed KMS key used to encrypt AWS
#   Network Firewall CloudWatch Logs when enabled.
#
# Input flow:
#   persistent.tfvars / AAP runtime values
#       -> variable declarations in variables.tf
#       -> naming/tag derivation in locals.tf
#       -> resources below
#
# Cross-stack dependency:
#   output.network_firewall_logging_kms_key_arn
#       -> Persistent Terraform state
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> currently Platform persistent_resources input
#
# This dependency is expected to move to the future Inspection stack when
# Network Firewall ownership is extracted from Platform.
################################################################################

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "network_firewall_logging_kms" {
  count = var.network_firewall_logging_kms_enabled ? 1 : 0

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
  count = var.network_firewall_logging_kms_enabled ? 1 : 0

  source = "../../modules/kms"

  description = local.network_firewall_logging_kms_description
  alias       = local.network_firewall_logging_kms_alias

  # Never bootstrap a temporary AAP/AWX STS session into the key policy.
  bootstrap_current_caller = false
  key_administrators       = var.kms_key_administrators

  additional_policy_documents = [
    data.aws_iam_policy_document.network_firewall_logging_kms[0].json
  ]

  tags = merge(
    local.org_tags,
    {
      "${var.organization_tag_key_prefix}service_name" = "network-firewall-logging"
    }
  )
}
