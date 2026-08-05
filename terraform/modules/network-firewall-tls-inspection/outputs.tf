##################################################################################################
# TLS Inspection Configuration Outputs
##################################################################################################
# ARN outputs plug directly into network-firewall-policy through
# firewall_policy.tls_inspection_configuration_arn.
output "tls_inspection_configurations" {
  description = "TLS inspection configuration attributes keyed by logical identifiers."
  value = {
    for key, configuration in aws_networkfirewall_tls_inspection_configuration.this : key => {
      arn                             = configuration.arn
      id                              = configuration.id
      name                            = configuration.name
      tls_inspection_configuration_id = configuration.tls_inspection_configuration_id
      #number_of_associations          = configuration.number_of_associations
      update_token          = configuration.update_token
      certificate_authority = configuration.certificate_authority
      certificates          = configuration.certificates
    }
  }
}
output "tls_inspection_configuration_arns" {
  description = "TLS inspection configuration ARNs keyed by logical identifiers."
  value = {
    for key, configuration in aws_networkfirewall_tls_inspection_configuration.this :
    key => configuration.arn
  }
}
output "tls_inspection_configuration_ids" {
  description = "AWS-generated TLS inspection configuration IDs keyed by logical identifiers."
  value = {
    for key, configuration in aws_networkfirewall_tls_inspection_configuration.this :
    key => configuration.tls_inspection_configuration_id
  }
}
