/*
 * General
 */

variable "tags" {
  description = "Tags supplied by the calling root module."
  type        = map(string)
  default     = {}
  nullable    = false
}

/*
 * EC2 Instances
 */

# A map(object({...})) is the strongest type constraint Terraform offers:
# it validates both the shape of every entry and the type of every
# attribute at plan time, long before any AWS API call is made.
#
# optional(type) makes an attribute omittable, while optional(type, default)
# supplies a secure fallback. Root volume and metadata settings below use
# defaults so enterprise security controls remain enabled unless explicitly
# overridden by an approved caller configuration.
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
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      encrypted             = optional(bool, true)
      delete_on_termination = optional(bool, true)
    }), {})

    metadata_options = optional(object({
      http_endpoint               = optional(string, "enabled")
      http_tokens                 = optional(string, "required")
      http_put_response_hop_limit = optional(number, 1)
      instance_metadata_tags      = optional(string, "disabled")
    }), {})

    tags = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      instance.root_block_device.encrypted
    ])

    error_message = "EC2 root volumes must be encrypted."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      instance.metadata_options.http_tokens == "required"
    ])

    error_message = "EC2 instances must require IMDSv2 by setting metadata_options.http_tokens to \"required\"."
  }
}
