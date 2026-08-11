output "saml_provider_arn" {
  description = "ARN returned by the IAM SAML provider module."
  value       = module.iam_saml_provider.saml_provider_arn
}

output "valid_until" {
  description = "SAML metadata expiration returned by the module."
  value       = module.iam_saml_provider.valid_until
}
