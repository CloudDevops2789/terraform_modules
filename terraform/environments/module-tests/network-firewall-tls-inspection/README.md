# Network Firewall TLS Inspection Module Test

## Purpose

This Terraform root validates the functionality and lifecycle of the `terraform/modules/network-firewall-tls-inspection` module.

The objective of this test is to verify that the module can successfully create, update, reference, and destroy AWS Network Firewall TLS Inspection Configurations using valid ACM certificate resources.

This test is intended only for module validation and is not a production deployment reference.

---

## Prerequisites

The following reusable modules must already be validated:

- `terraform/modules/network-firewall-policy`

AWS credentials must have permissions to create and manage:

- AWS Certificate Manager (ACM)
- AWS Network Firewall
- AWS IAM (if required by the environment)

---

## Resources Created

This module test creates:

- One RSA private key using the Terraform TLS provider
- One short-lived self-signed Certificate Authority (CA)
- One imported ACM certificate
- One AWS Network Firewall TLS Inspection Configuration
- One AWS Network Firewall Policy referencing the TLS Inspection Configuration

No Network Firewall, VPC, or application infrastructure is deployed.

---

## Test PKI Notice

This test intentionally generates a temporary Certificate Authority to validate Terraform functionality.

This PKI exists only for automated module testing.

It must **never** be used as:

- an enterprise root CA
- an enterprise intermediate CA
- a production inspection CA
- a VPN authentication CA
- a server certificate authority
- an organizational trust anchor

The generated certificate is disposable and should exist only for the lifetime of this module test.

---

## Security Considerations

The generated private key is stored in Terraform state.

For this reason:

- use only an encrypted backend
- restrict backend access to authorized engineers
- destroy the test environment immediately after validation
- never reuse the generated certificate or private key

Production certificate lifecycle management must remain outside this module.

---

## Enterprise Certificate Model

This test generates certificates only because an AWS Network Firewall TLS Inspection Configuration requires valid ACM certificates.

Production environments should instead provide ACM certificate ARNs issued through the organization's approved PKI process.

Typical enterprise sources include:

- Microsoft Active Directory Certificate Services (AD CS)
- AWS Private CA (where supported)
- Venafi
- DigiCert
- HashiCorp Vault PKI
- Corporate PKI platforms
- Imported ACM certificates

The reusable Terraform module consumes existing ACM certificate ARNs and is intentionally independent of certificate issuance.

---

## Backend

The Terraform state key is:

```text
module-tests/network-firewall-tls-inspection/terraform.tfstate
```

The backend should provide:

- encryption at rest
- access control
- versioning
- state locking

---

## Deployment

```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
terraform plan -input=false
```

---

## Expected Result

The deployment should:

- generate a temporary test CA
- import the certificate into ACM
- create a TLS Inspection Configuration
- associate the configuration with a Network Firewall Policy

The final Terraform plan should report:

```text
No changes. Your infrastructure matches the configuration.
```

The outputs should include:

- TLS Inspection Configuration ARN
- ACM Certificate ARN
- Firewall Policy ARN
- TLS Inspection association details

---

## Destroy

```bash
terraform destroy -input=false
```

The destroy operation should successfully remove:

- TLS Inspection Configuration
- Firewall Policy
- ACM Certificate
- Generated test certificate resources

---

## Scope

This test validates:

- outbound TLS inspection configuration
- traffic scope definition
- certificate revocation settings
- firewall policy integration
- TLS session holding
- Terraform lifecycle behavior
- idempotency
- destroy operations

This test does **not** validate:

- production PKI lifecycle
- certificate rotation
- certificate renewal
- client trust distribution
- inbound TLS inspection
- TLS traffic decryption
- end-to-end packet inspection
- application connectivity

Those responsibilities belong to separate enterprise PKI, networking, and security validation processes.