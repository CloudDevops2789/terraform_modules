##################################################################################################
# Compute Variables
##################################################################################################

variable "recovery_ssh_key_pairs" {
  description = "Approved SSH key-pair registry. Map keys are the effective AWS EC2 key-pair names."

  type = map(object({
    source          = string
    public_key_path = optional(string)
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key_name, config in var.recovery_ssh_key_pairs :
      (
        length(trimspace(key_name)) > 0 &&
        contains(["existing", "managed"], config.source)
      )
    ])

    error_message = "Recovery SSH key-pair names must be non-empty and source must be existing or managed."
  }

  validation {
    condition = alltrue([
      for config in values(var.recovery_ssh_key_pairs) :
      (
        config.source == "managed"
        ? (
          config.public_key_path != null &&
          length(trimspace(config.public_key_path)) > 0
        )
        : config.public_key_path == null
      )
    ])

    error_message = "Managed SSH key pairs require public_key_path; existing key pairs must not set it."
  }
}

#### Tagging Variables #######
