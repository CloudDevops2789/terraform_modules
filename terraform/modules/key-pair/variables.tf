variable "default_tags" {
  description = "Default tags applied to all key pairs."
  type        = map(string)
  default     = {}
}

# public_key is required; tags is optional with a {} default so callers
# can omit it entirely. The map key becomes the AWS key pair name.
variable "key_pairs" {
  description = "Key pairs to create."

  type = map(object({
    public_key = string
    tags       = optional(map(string), {})
  }))

  default = {}
}