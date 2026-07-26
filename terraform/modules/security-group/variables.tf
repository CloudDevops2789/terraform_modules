variable "default_tags" {
  description = "Default tags applied to all security groups."
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  description = "Security groups to create."

  type = map(object({
    description = string
    vpc_id      = string
    tags        = optional(map(string), {})
  }))

  default = {}
}