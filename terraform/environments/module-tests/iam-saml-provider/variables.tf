variable "aws_region" {
  description = "AWS Region used by the module test."
  type        = string
  default     = "us-east-1"
}

variable "provider_name" {
  description = "Name used for the test IAM SAML provider."
  type        = string
  default     = "module-test-client-vpn"
}

variable "saml_metadata_document" {
  description = "SAML metadata XML supplied to the IAM SAML provider module."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied by the module test."
  type        = map(string)
  default     = {}
}
