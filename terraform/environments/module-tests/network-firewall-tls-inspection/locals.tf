locals {
  default_tags = merge(
    {
      fv_it_cost_center       = var.org_it_cost_center
      fv_department           = var.org_department
      fv_cmdb_calculated_app  = var.org_cmdb_calculated_app
      fv_business_criticality = var.org_business_criticality
      fv_environment          = var.org_environment
      fv_security_trust_zone  = var.org_security_trust_zone
      fv_data_classification  = var.org_data_classification
      Project                 = var.project_name
      ManagedBy               = "Terraform"
    },
    var.additional_tags
  )
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
