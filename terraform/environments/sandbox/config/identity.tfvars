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

managed_ad_enabled = false

# Define the approved domain and edition before enabling the directory.
managed_ad_configuration = null
