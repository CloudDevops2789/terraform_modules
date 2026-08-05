variable "tags" {
  description = "Tags supplied by the calling root module."
  type        = map(string)
  default     = {}
  nullable    = false
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
