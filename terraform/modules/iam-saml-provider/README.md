# IAM SAML Provider

Reusable Terraform module for creating an AWS IAM SAML identity provider from an approved SAML 2.0 metadata document.

## Purpose

This module owns only the AWS IAM SAML provider resource.

It does not manage:

- Corporate identity-provider applications
- MFA or conditional-access policies
- SAML metadata generation
- Client VPN endpoints
- IAM roles or permission policies
- AAP authentication or role assumption

This separation allows the module to be reused independently by workloads that require AWS SAML federation.

## Architecture

```text
Corporate Identity Provider
        |
        | Approved SAML metadata XML
        v
iam-saml-provider
        |
        | saml_provider_arn
        v
Consumer
(e.g. AWS Client VPN)
```

## Usage
```
module "client_vpn_saml_provider" {
  source = "../../modules/iam-saml-provider"

  name                   = "client-vpn-saml"
  saml_metadata_document = var.saml_metadata_document

  tags = var.tags
}
```
## Validation

```bash
scripts/ci/terraform-validate-root.sh \
  terraform/environments/module-tests/iam-saml-provider
```