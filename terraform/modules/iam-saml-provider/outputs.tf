##################################################################################################
# IAM SAML Identity Provider
##################################################################################################

output "saml_provider_arn" {
  description = "ARN of the IAM SAML identity provider."
  value       = aws_iam_saml_provider.this.arn
}

output "saml_provider_name" {
  description = "Name of the IAM SAML identity provider."
  value       = aws_iam_saml_provider.this.name
}

output "valid_until" {
  description = "Expiration date and time derived from the SAML metadata document."
  value       = aws_iam_saml_provider.this.valid_until
}