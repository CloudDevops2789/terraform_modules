locals {
  default_tags = merge(
    {
      Name = var.name
    },
    var.tags
  )

  authentication_options = {
    for option in concat(
      contains(["directory", "directory_and_mutual"], var.authentication_type)
      ? [{
        key                  = "directory"
        type                 = "directory-service-authentication"
        active_directory_id  = var.active_directory_id
        root_certificate_arn = null
        saml_provider_arn    = null
      }]
      : [],
      contains(["certificate", "directory_and_mutual"], var.authentication_type)
      ? [{
        key                  = "certificate"
        type                 = "certificate-authentication"
        active_directory_id  = null
        root_certificate_arn = var.root_certificate_chain_arn
        saml_provider_arn    = null
      }]
      : [],
      var.authentication_type == "federated"
      ? [{
        key                  = "federated"
        type                 = "federated-authentication"
        active_directory_id  = null
        root_certificate_arn = null
        saml_provider_arn    = var.saml_provider_arn
      }]
      : []
    ) : option.key => option
  }
}
