# AWS Network Firewall TLS Inspection Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.0, < 7.0`
## Purpose
This module creates AWS Network Firewall TLS inspection configurations:
```text
network-firewall-tls-inspection
             ↓
network-firewall-policy
             ↓
network-firewall
             ↓
network-firewall-logging
```

## Production ownership model
This module configures AWS Network Firewall TLS inspection only. It does not own certificate issuance or enterprise PKI governance.

Recommended responsibility split:

- Cyber Resilience Automation owns the Terraform module, deployment automation, testing, drift detection, and operational integration.
- PKI or Cloud Security owns certificate issuance, CA hierarchy, private-key custody, renewal, revocation, and trust distribution.
- Network Security approves TLS inspection scope, bypass requirements, decrypted-traffic controls, and firewall policy behavior.

For sandbox and module-test environments, the consuming root may generate short-lived non-production certificates. Production environments should pass approved ACM certificate ARNs issued through the organization’s certificate-management process.

The module accepts existing AWS Certificate Manager certificate ARNs and optional KMS key identifiers. It does not create certificates, private keys, ACM resources, KMS keys, firewall policies, firewalls, logging destinations, or route tables.
## Inspection modes
### Outbound inspection
Provide `certificate_authority_arn`. The certificate must be an imported CA certificate in ACM that Network Firewall can use to generate replacement server certificates.
### Inbound inspection
Provide one or more `server_certificates`. Network Firewall uses those ACM server certificates to decrypt traffic addressed to the corresponding protected services.
### Combined inspection
A single server certificate configuration can include both an outbound CA certificate and inbound server certificates.
## Scoped traffic
Every server certificate configuration requires at least one scope. A scope can match:
- TCP protocol number `6`
- Source IPv4 CIDRs
- Source port ranges
- Destination IPv4 CIDRs
- Destination port ranges
Network Firewall automatically creates a reverse scope so TLS termination is handled bidirectionally.
## Outbound example
```hcl
module "network_firewall_tls_inspection" {
  source = "../../modules/network-firewall-tls-inspection"
  tls_inspection_configurations = {
    outbound = {
      name        = "ire-outbound-tls-inspection"
      description = "Decrypts approved outbound TLS traffic."
      server_certificate_configurations = [{
        #certificate_authority_arn = aws_acm_certificate.outbound_ca.arn
        certificate_authority_arn = var.tls_inspection_ca_arn
        check_certificate_revocation_status = {
          revoked_status_action = "REJECT"
          unknown_status_action = "PASS"
        }
        scopes = [{
          protocols = [6]
          sources = [{
            address_definition = "10.0.0.0/8"
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
  tags = {
    Project   = "AWS-IRE"
    ManagedBy = "Terraform"
  }
}
```
## Inbound example
```hcl
module "network_firewall_tls_inspection" {
  source = "../../modules/network-firewall-tls-inspection"
  tls_inspection_configurations = {
    inbound = {
      name = "ire-inbound-tls-inspection"
      server_certificate_configurations = [{
        server_certificates = [{
  resource_arn = var.application_certificate_arn
      }]
        scopes = [{
          protocols = [6]
          sources = [{
            address_definition = "0.0.0.0/0"
          }]
          destinations = [{
            address_definition = "10.10.10.10/32"
          }]
          destination_ports = [{
            from_port = 443
          }]
        }]
      }]
    }
  }
}
```
## Firewall policy integration
Use the ARN output directly:
```hcl
module "network_firewall_policy" {
  source = "../../modules/network-firewall-policy"
  firewall_policies = {
    inspection = {
      name = "ire-inspection-policy"
      firewall_policy = {
        tls_inspection_configuration_arn = module.network_firewall_tls_inspection.tls_inspection_configuration_arns["outbound"]
        enable_tls_session_holding       = true
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
```
## Revocation checking
Revocation checking is available only for outbound inspection and therefore requires `certificate_authority_arn`.
Supported actions:
- `PASS`
- `DROP`
- `REJECT`
TLS logging should be enabled through `network-firewall-logging` to observe revocation-check failures.
## Certificate requirements
Certificate resources remain outside this module because certificate issuance, private-key custody, renewal, validation, and trust distribution are separate security responsibilities.
Important operational requirements include:
- Inbound certificates must be present in ACM and valid for the protected service.
- Outbound inspection requires a suitable imported CA certificate.
- Expired, deleted, or revoked certificates can cause client-side TLS failures.
- Client devices must trust the outbound inspection CA.
## Encryption
Omit `encryption_configuration` to use AWS-owned encryption. For a customer-managed key:
```hcl
encryption_configuration = {
  type   = "CUSTOMER_KMS"
  key_id = aws_kms_key.network_firewall.arn
}
```
The key policy must permit AWS Network Firewall to use the key.
## Outputs
- `tls_inspection_configurations`
- `tls_inspection_configuration_arns`
- `tls_inspection_configuration_ids`

## Module test
The isolated apply test creates:

- A short-lived RSA private key and self-signed test CA using the TLS provider
- An imported ACM certificate
- One outbound TLS inspection configuration
- One firewall policy referencing the TLS inspection configuration

The test PKI is strictly non-production and exists only to validate the Terraform module.

The generated private key is stored in Terraform state. Use only an isolated, encrypted, access-controlled test backend. Do not reuse the key, certificate, or CA as an organizational trust anchor. Destroy the environment immediately after validation.
