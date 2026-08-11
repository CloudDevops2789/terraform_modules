# IAM SAML Provider Module Test

Validation environment for the reusable `terraform/modules/iam-saml-provider` module.

This test verifies that the module can be consumed independently using generic,
customer-neutral inputs.

By default, synthetic SAML metadata from `locals.tf` is used for Terraform
validation. It must not be used as production identity-provider metadata.

Real enterprise SAML metadata must be supplied through an approved identity or
automation workflow and must not be committed to this repository.

## Validation

From the repository root, run:

    scripts/ci/terraform-validate-root.sh terraform/environments/module-tests/iam-saml-provider

The changed-module CI workflow automatically discovers this validation root
when Terraform implementation files in the reusable `iam-saml-provider`
module change.
