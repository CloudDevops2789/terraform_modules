##################################################################################################
# Sandbox Identity Stack Configuration
#
# Organization tags are supplied through common-tags.tfvars.
# Managed Microsoft AD remains disabled until the identity/security workflow
# and credential handling model are approved.
##################################################################################################

# Identity placement is configuration, not Terraform implementation logic.
identity_placement = {
  vpc_key               = "core_recovery"
  subnet_group          = "directory-services"
  required_subnet_count = 2
}

# Managed AD remains cost-free until explicitly enabled through Git-controlled configuration.
# Only routed administrative networks may reach the managed directory.
managed_ad_client_vpc_keys = ["recovery_access"]

managed_ad_enabled = true

# Define the approved domain and edition before enabling the directory.
managed_ad_configuration = {
  domain_name = "ad.fairview-ire.org"
  short_name  = "FVIRE"
  edition     = "Standard"
}

# Resolve the clean administrative directory through Route 53 Resolver without
# creating a private hosted zone for the directory-owned DNS namespace.
managed_ad_dns_resolver = {
  enabled = true

  endpoint_name       = "fv-ire-sandbox-managed-ad-dns-outbound"
  rule_name           = "fv-ire-sandbox-managed-ad-domain"
  security_group_name = "fv-ire-sandbox-managed-ad-dns-sg"

  vpc_key               = "core_recovery"
  subnet_group          = "endpoints"
  required_subnet_count = 2

  # Protected Data is deliberately excluded: restored production-derived
  # workloads must not automatically resolve against the clean admin domain.
  associated_vpc_keys = [
    "core_recovery",
    "recovery_access"
  ]
}
