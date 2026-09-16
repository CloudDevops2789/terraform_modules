################################################################################
# Persistent Stack Derived Values
#
# Terraform reference resolution:
#
#   var.<name>
#     Refers to a variable declared in variables.tf in this same Terraform root.
#
#   local.<name>
#     Refers to a value defined in a locals block in this Terraform root.
#
# Terraform loads every *.tf file in this directory as one root module.
# main.tf does NOT call locals.tf or variables.tf. Filenames provide human
# organization only; references establish the dependency graph.
################################################################################

locals {
  ##############################################################################
  # Resource Naming
  #
  # Source:
  #   var.name_prefix -> variables.tf
  #
  # Consumers:
  #   main.tf Backup vault and KMS module blocks
  ##############################################################################

  standard_backup_vault_name   = "${var.name_prefix}-standard-backup-vault"
  air_gapped_backup_vault_name = "${var.name_prefix}-airgap-backup-vault"

  network_firewall_logging_kms_alias = "${var.name_prefix}-network-firewall-logs"

  network_firewall_logging_kms_description = (
    "Persistent customer-managed KMS key for IRE Network Firewall CloudWatch logs"
  )

  ##############################################################################
  # Organization Tags
  #
  # Sources:
  #   organization tagging variables declared in variables.tf
  #
  # Consumers:
  #   provider.tf -> AWS provider default_tags
  #   main.tf     -> module/resource-specific tag composition
  ##############################################################################

  org_tags = var.organization_tags
}
