##################################################################################################
# IAM Module Variables
##################################################################################################

variable "roles" {
  description = "IAM roles managed by this module."

  type = map(object({
    name                  = optional(string)
    description           = optional(string)
    path                  = optional(string, "/")
    assume_role_policy    = string
    permissions_boundary  = optional(string)
    max_session_duration  = optional(number, 3600)
    force_detach_policies = optional(bool, false)

    managed_policy_arns = optional(set(string), [])
    inline_policies     = optional(map(string), {})

    create_instance_profile = optional(bool, false)
    instance_profile_name   = optional(string)

    tags = optional(map(string), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for role in values(var.roles) :
      can(jsondecode(role.assume_role_policy))
    ])
    error_message = "Each assume_role_policy must contain valid JSON."
  }

  validation {
    condition = alltrue([
      for role in values(var.roles) :
      role.max_session_duration >= 3600 &&
      role.max_session_duration <= 43200
    ])
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for role in values(var.roles) : [
        for policy in values(role.inline_policies) :
        can(jsondecode(policy))
      ]
    ]))
    error_message = "Every inline policy must contain valid JSON."
  }
}

variable "tags" {
  description = "Tags applied to IAM roles created by this module."
  type        = map(string)
  default     = {}
  nullable    = false
}
