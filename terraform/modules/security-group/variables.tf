variable "tags" {
  description = "Tags supplied by the calling root module."
  type        = map(string)
  default     = {}
  nullable    = false
}

# description is required because AWS requires a non-empty description on
# every security group and rejects the request otherwise - encoding that
# in the type turns an API error into a plan-time error.
variable "security_groups" {
  description = "Security groups to create."

  type = map(object({
    name        = optional(string)
    description = string
    vpc_id      = string
    tags        = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for security_group in values(var.security_groups) :
      security_group.name == null ? true : length(trimspace(security_group.name)) > 0
    ])

    error_message = "Security group names must be null or non-empty strings."
  }

  validation {
    condition = alltrue([
      for security_group in values(var.security_groups) :
      length(trimspace(security_group.description)) > 0
    ])

    error_message = "Security group descriptions must be non-empty strings."
  }

  validation {
    condition = length(distinct([
      for security_group_key, security_group in var.security_groups :
      "${security_group.vpc_id}/${lower(coalesce(security_group.name, security_group_key))}"
    ])) == length(var.security_groups)

    error_message = "Effective security group names must be unique within each VPC, ignoring case."
  }
}
