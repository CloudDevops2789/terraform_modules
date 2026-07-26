/*
 * General
 */

variable "default_tags" {
  description = "Default tags applied to all EC2 instances."
  type        = map(string)
  default     = {}
}

/*
 * EC2 Instances
 */

# A map(object({...})) is the strongest type constraint Terraform offers:
# it validates both the shape of every entry and the type of every
# attribute at plan time, long before any AWS API call is made.
#
# optional(type) makes an attribute omittable (it becomes null), while
# optional(type, default) supplies a fallback value instead. Nesting an
# optional() object - as root_block_device does below - makes a whole
# block of settings opt-in.
#
# Defaulting the map itself to {} means the module is valid with no
# instances at all, which keeps it composable in environments that only
# need it conditionally.
variable "instances" {
  description = "EC2 instances to create."

  type = map(object({
    ami           = string
    instance_type = string
    subnet_id     = string

    vpc_security_group_ids = optional(list(string), [])

    key_name             = optional(string)
    iam_instance_profile = optional(string)

    private_ip = optional(string)

    associate_public_ip_address = optional(bool, false)

    root_block_device = optional(object({
      volume_size           = number
      volume_type           = optional(string, "gp3")
      encrypted             = optional(bool, true)
      delete_on_termination = optional(bool, true)
    }))

    tags = optional(map(string), {})
  }))

  default = {}
}