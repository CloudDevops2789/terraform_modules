##################################################################################################
# Organization Tagging Variables
##################################################################################################











##################################################################################################
# Portable environment naming
##################################################################################################

##################################################################################################
# Organization Resource Tags
##################################################################################################

variable "organization_tags" {
  description = "Organization-defined AWS resource tags. Keys and values are passed through exactly as supplied."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.organization_tags) :
      length(trimspace(key)) > 0 &&
      length(key) <= 128 &&
      !startswith(lower(key), "aws:")
    ])

    error_message = "Organization tag keys must be 1-128 characters and must not use the reserved aws: prefix."
  }

  validation {
    condition = alltrue([
      for value in values(var.organization_tags) :
      length(value) <= 256
    ])

    error_message = "Organization tag values must not exceed 256 characters."
  }
}
