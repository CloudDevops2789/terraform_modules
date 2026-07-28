############################################################
# Locals
############################################################

locals {
  effective_administrators = (
    length(var.key_administrators) > 0
    ? var.key_administrators
    : var.bootstrap_current_caller
    ? [data.aws_caller_identity.current.arn]
    : []
  )
}

############################################################
# IAM Policy Document
#
# Reserved Statement IDs
# ----------------------
# EnableRootPermissions
# AllowKeyAdministration
# AllowKeyUsage
#
# Consumers extending the policy via
# additional_policy_documents must not reuse these
# statement IDs. SID collisions will fail during
# Terraform planning.
############################################################

data "aws_iam_policy_document" "key_policy" {
  source_policy_documents = var.additional_policy_documents

  statement {
    sid       = "EnableRootPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
  statement {
    sid    = "AllowKeyAdministration"
    effect = "Allow"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:CreateAlias",
      "kms:DeleteAlias"
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = local.effective_administrators
    }
  }
  dynamic "statement" {
    for_each = length(var.key_user_principals) > 0 ? [1] : []

    content {
      sid    = "AllowKeyUsage"
      effect = "Allow"

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_user_principals
      }
    }
  }
}

############################################################
# KMS Key
############################################################

resource "aws_kms_key" "this" {
  description             = var.description
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  multi_region            = var.multi_region

  policy = data.aws_iam_policy_document.key_policy.json

  tags = var.tags

  lifecycle {
    precondition {
      condition = (
        length(local.effective_administrators) > 0 ||
        var.acknowledge_root_only_administration
      )

      error_message = "No key administrators resolved. Either specify key_administrators, enable bootstrap_current_caller, or explicitly acknowledge root-only administration."
    }
  }
}