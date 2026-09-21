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
  "fv:it-cost-center"             = "10000-70100-8337"
  "fv:department"                 = "Cybersecurity - Technology Resilience and Recovery"
  "fv:app-name"                   = "Fairview IRE"
  "fv:it-app-owner"               = "Bruce Zamaere"
  "fv:environment"                = "sandbox"
  "fv:project-name"               = "CyberRecoveryBlueprint"
  "fv:managed-by"                 = "Ansible_Automation_Platform"
  "fv:cmdb-calculated-app-number" = "APM0002437"
}
