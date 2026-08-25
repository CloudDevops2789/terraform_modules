locals {
  test_saml_metadata_document = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
      entityID="https://example.invalid/client-vpn">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <SingleSignOnService
          Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
          Location="https://example.invalid/saml/sso"/>
        <!--
        This metadata is intentionally synthetic and exists only to exercise
        the Terraform module interface during static validation. It must never
        be used as production identity-provider metadata. Production metadata
        must be supplied by the organization's approved identity provider.
        Padding is intentionally included so the test document satisfies the
        AWS SAML metadata minimum-length requirement without containing any
        customer-specific identity information.
        ........................................................................
        ........................................................................
        ........................................................................
        ........................................................................
        ........................................................................
        ........................................................................
        ........................................................................
        ........................................................................
        -->
      </IDPSSODescriptor>
    </EntityDescriptor>
  XML

  effective_saml_metadata_document = coalesce(
    var.saml_metadata_document,
    local.test_saml_metadata_document
  )

  tags = merge(
    {
      "org_environment"  = "test"
      "org_managed_by"   = "Terraform"
      "org_project_name" = "AWS-IRE"
    },
    var.tags
  )
}
