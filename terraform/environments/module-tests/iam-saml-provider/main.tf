module "iam_saml_provider" {
  source = "../../../modules/iam-saml-provider"

  name                   = var.provider_name
  saml_metadata_document = local.effective_saml_metadata_document

  tags = local.tags
}
