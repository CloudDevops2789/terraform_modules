##################################################################################################
# SAML Provider Configuration
##################################################################################################

variable "name" {
  description = "Name of the IAM SAML identity provider."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(trimspace(var.name)) >= 1 &&
      length(trimspace(var.name)) <= 128 &&
      can(regex("^[A-Za-z0-9._-]+$", var.name))
    )

    error_message = "name must contain 1 to 128 characters using only letters, numbers, '.', '_', or '-'."
  }
}

variable "saml_metadata_document" {
  description = "SAML 2.0 metadata XML document generated and approved by the external identity provider."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.saml_metadata_document) >= 1000 &&
      length(var.saml_metadata_document) <= 10000000
    )

    error_message = "saml_metadata_document must contain between 1,000 and 10,000,000 characters."
  }
}

##################################################################################################
# Common Tags
##################################################################################################

variable "tags" {
  description = "Tags to apply to the IAM SAML identity provider."
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = length(var.tags) <= 50
    error_message = "tags must not contain more than 50 entries."
  }
}