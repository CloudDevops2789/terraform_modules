variable "default_tags" {
  description = "Default tags applied to all key pairs."
  type        = map(string)
  default     = {}
}

variable "key_pairs" {
  description = "Key pairs to create."

  type = map(object({
    public_key = string
    tags       = optional(map(string), {})
  }))

  default = {}
}