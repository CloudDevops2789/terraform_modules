############################################
# AWS Backup Selection
############################################

# Associates one or more AWS resources
# with an AWS Backup Plan.
#
# The Backup Selection identifies which
# resources AWS Backup should protect
# using the specified IAM Role.
#
resource "aws_backup_selection" "this" {

  name = var.name

  plan_id = var.backup_plan_id

  iam_role_arn = var.iam_role_arn

  resources = var.resources

}