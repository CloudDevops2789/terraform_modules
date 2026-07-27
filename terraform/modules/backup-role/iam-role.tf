############################################
# IAM Trust Policy
############################################

# Defines which AWS service is allowed to
# assume this IAM Role.
#
data "aws_iam_policy_document" "assume_role" {

  statement {

    effect = "Allow"

    principals {

      type = "Service"

      identifiers = [
        "backup.amazonaws.com"
      ]

    }

    actions = [
      "sts:AssumeRole"
    ]

  }

}

############################################
# IAM Role
############################################

resource "aws_iam_role" "this" {

  name = var.name

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags

}

############################################
# AWS Managed Backup Policy
############################################

resource "aws_iam_role_policy_attachment" "backup" {

  role = aws_iam_role.this.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"

}