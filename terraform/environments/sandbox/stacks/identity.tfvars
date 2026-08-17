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
