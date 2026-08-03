locals {
  default_tags = {
    TestedModule = "network-firewall-tls-inspection"
  }
  tls_inspection_configurations = {
    outbound = {
      name        = "module-test-network-firewall-tls-inspection"
      description = "Validates outbound TLS inspection configuration and policy association."
      server_certificate_configurations = [{
        certificate_authority_arn = aws_acm_certificate.outbound_ca.arn
        check_certificate_revocation_status = {
          revoked_status_action = "REJECT"
          unknown_status_action = "PASS"
        }
        scopes = [{
          protocols = [6]
          sources = [{
            address_definition = "10.255.0.0/16"
          }]
          source_ports = [{
            from_port = 0
            to_port   = 65535
          }]
          destinations = [{
            address_definition = "0.0.0.0/0"
          }]
          destination_ports = [{
            from_port = 443
            to_port   = 443
          }]
        }]
      }]
    }
  }
  firewall_policies = {
    tls_inspection = {
      name        = "module-test-network-firewall-tls-policy"
      description = "Validates TLS inspection configuration association and session holding."
      firewall_policy = {
        enable_tls_session_holding       = true
        tls_inspection_configuration_arn = module.network_firewall_tls_inspection.tls_inspection_configuration_arns["outbound"]
        stateless_default_actions = [
          "aws:forward_to_sfe"
        ]
        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
      }
    }
  }
}
