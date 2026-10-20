##################################################################################################
# IRE Operational Notifications
#
# SNS provides a lightweight notification channel for recovery lifecycle events,
# approvals, failures, and environment status.
#
# The AWS-managed SNS KMS key is used initially to avoid introducing another
# customer-managed key solely for notification transport.
##################################################################################################

resource "aws_sns_topic" "ire_notifications" {
  count = var.notifications_enabled ? 1 : 0

  name              = "${local.name_prefix}-notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.org_tags,
    {
      Name    = "${local.name_prefix}-notifications"
      Purpose = "IRE operational notifications"
    }
  )
}

resource "aws_sns_topic_subscription" "ire_notification_email" {
  for_each = var.notifications_enabled ? var.notification_email_subscriptions : toset([])

  topic_arn = aws_sns_topic.ire_notifications[0].arn
  protocol  = "email"
  endpoint  = each.value
}
