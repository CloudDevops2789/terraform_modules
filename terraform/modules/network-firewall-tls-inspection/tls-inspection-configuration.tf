##################################################################################################
# AWS Network Firewall TLS Inspection Configurations
##################################################################################################
# Network Firewall decrypts matching TLS traffic, applies stateful inspection, and re-encrypts the
# traffic before forwarding it. AWS automatically creates reverse scopes for bidirectional handling.
resource "aws_networkfirewall_tls_inspection_configuration" "this" {
  for_each    = local.tls_inspection_configurations
  description = each.value.description
  name        = each.value.name
  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration == null ? [] : [each.value.encryption_configuration]
    content {
      key_id = encryption_configuration.value.key_id
      type   = encryption_configuration.value.type
    }
  }
  tls_inspection_configuration {
    dynamic "server_certificate_configuration" {
      for_each = each.value.server_certificate_configurations
      content {
        certificate_authority_arn = server_certificate_configuration.value.certificate_authority_arn
        dynamic "check_certificate_revocation_status" {
          for_each = server_certificate_configuration.value.check_certificate_revocation_status == null ? [] : [server_certificate_configuration.value.check_certificate_revocation_status]
          content {
            revoked_status_action = check_certificate_revocation_status.value.revoked_status_action
            unknown_status_action = check_certificate_revocation_status.value.unknown_status_action
          }
        }
        dynamic "scope" {
          for_each = server_certificate_configuration.value.scopes
          content {
            protocols = scope.value.protocols
            dynamic "destination" {
              for_each = scope.value.destinations
              content {
                address_definition = destination.value.address_definition
              }
            }
            dynamic "destination_ports" {
              for_each = scope.value.destination_ports
              content {
                from_port = destination_ports.value.from_port
                to_port   = coalesce(destination_ports.value.to_port, destination_ports.value.from_port)
              }
            }
            dynamic "source" {
              for_each = scope.value.sources
              content {
                address_definition = source.value.address_definition
              }
            }
            dynamic "source_ports" {
              for_each = scope.value.source_ports
              content {
                from_port = source_ports.value.from_port
                to_port   = coalesce(source_ports.value.to_port, source_ports.value.from_port)
              }
            }
          }
        }
        dynamic "server_certificate" {
          for_each = server_certificate_configuration.value.server_certificates
          content {
            resource_arn = server_certificate.value.resource_arn
          }
        }
      }
    }
  }
  tags = each.value.tags
  timeouts {
    create = each.value.timeouts.create
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}
