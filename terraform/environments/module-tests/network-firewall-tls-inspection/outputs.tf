##################################################################################################
# Validation Outputs
##################################################################################################
output "tls_inspection_configurations" {
  description = "TLS inspection configurations created by the module test."
  value       = module.network_firewall_tls_inspection.tls_inspection_configurations
}
output "tls_inspection_configuration_arns" {
  description = "TLS inspection configuration ARNs consumed by firewall policies."
  value       = module.network_firewall_tls_inspection.tls_inspection_configuration_arns
}
output "firewall_policy_arns" {
  description = "Firewall policy ARNs associated with the TLS inspection configuration."
  value       = module.network_firewall_policy.firewall_policy_arns
}
output "test_ca_certificate_arn" {
  description = "Imported ACM test CA certificate ARN."
  value       = aws_acm_certificate.outbound_ca.arn
}
