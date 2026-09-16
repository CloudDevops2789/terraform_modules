##################################################################################################
# Sandbox Common Organization Tags
#
# Shared by Persistent, Platform, Inspection, Identity, Remote Access,
# and Recovery stacks.
#
# Keys below are the exact AWS tag keys. Terraform does not rename,
# prefix, or otherwise transform them.
##################################################################################################

organization_tags = {
  "org:it_cost_center"       = "00000"
  "org:department"           = "Cyber_Resilience"
  "org:cmdb_calculated_app"  = "Isolated_Recovery_Environment"
  "org:business_criticality" = "4"
  "org:environment"          = "dev"
  "org:data_classification"  = "Internal"
  "org:project_name"         = "IsolatedRecoveryEnvironment"
  "org:managed_by"           = "Terraform"
}
