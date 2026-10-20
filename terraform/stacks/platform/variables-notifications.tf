##################################################################################################
# IRE Notifications
##################################################################################################

variable "notifications_enabled" {
  description = "Enable the shared IRE SNS notification topic."
  type        = bool
  default     = false
}

variable "notification_email_subscriptions" {
  description = "Email addresses subscribed to the IRE notification topic. Each recipient must confirm the SNS subscription."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for address in var.notification_email_subscriptions :
      can(regex("^[^[:space:]@]+@[^[:space:]@]+\\.[^[:space:]@]+$", address))
    ])

    error_message = "notification_email_subscriptions must contain syntactically valid email addresses."
  }
}
