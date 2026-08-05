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
    description = string
    vpc_id      = string
    tags        = optional(map(string), {})
  }))

  default = {}
}
