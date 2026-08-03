locals {
  ##################################################################################################
  # TLS Inspection Configuration Normalization
  ##################################################################################################
  # Resource-specific tags override common module tags while provider-level default_tags remain
  # controlled by the consuming Terraform root module.
  tls_inspection_configurations = {
    for key, configuration in var.tls_inspection_configurations : key => merge(configuration, {
      tags = merge(var.tags, configuration.tags)
    })
  }
}
