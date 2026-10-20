##################################################################################################
# IRE Notification Contract
##################################################################################################

output "notification_topic_arn" {
  description = "ARN of the IRE operational notification SNS topic, or null when notifications are disabled."
  value = (
    var.notifications_enabled
    ? aws_sns_topic.ire_notifications[0].arn
    : null
  )
}

output "notification_topic_name" {
  description = "Name of the IRE operational notification SNS topic, or null when notifications are disabled."
  value = (
    var.notifications_enabled
    ? aws_sns_topic.ire_notifications[0].name
    : null
  )
}
