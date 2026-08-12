##################################################################################################
# Client VPN and Federation Variables
##################################################################################################

variable "authentication_type" {
  description = "Client VPN authentication method. Supported values are certificate and federated."
  type        = string
  default     = "certificate"

  validation {
    condition = contains([
      "certificate",
      "federated",
    ], var.authentication_type)

    error_message = "authentication_type must be either certificate or federated."
  }
}

variable "server_certificate_arn" {
  description = "ACM server certificate ARN."
  type        = string
}

variable "root_certificate_chain_arn" {
  description = "ACM root CA certificate ARN. Required for certificate authentication."
  type        = string
  default     = null
  nullable    = true
}

variable "saml_provider_arn" {
  description = "Existing IAM SAML identity provider ARN used when manage_saml_provider is false."
  type        = string
  default     = null
  nullable    = true
}

variable "manage_saml_provider" {
  description = "Whether Terraform manages the IAM SAML identity provider lifecycle for Client VPN."
  type        = bool
  default     = false
}

variable "saml_provider_name" {
  description = "Optional name override for the Terraform-managed IAM SAML provider."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.saml_provider_name == null ? true : (
      length(trimspace(var.saml_provider_name)) >= 1 &&
      length(trimspace(var.saml_provider_name)) <= 128 &&
      can(regex("^[A-Za-z0-9._-]+$", var.saml_provider_name))
    )

    error_message = "saml_provider_name must contain 1 to 128 characters using only letters, numbers, '.', '_', or '-'."
  }
}

variable "saml_metadata_document" {
  description = "Approved SAML 2.0 metadata XML used when Terraform manages the IAM SAML provider."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.saml_metadata_document == null ? true : (
      length(var.saml_metadata_document) >= 1000 &&
      length(var.saml_metadata_document) <= 10000000
    )

    error_message = "saml_metadata_document must contain between 1,000 and 10,000,000 characters when provided."
  }
}
