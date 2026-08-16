##################################################################################################
# Sandbox Recovery Stack Configuration
#
# Stable Recovery behavior is Git controlled.
# Runtime intent such as demo_ec2_enabled and ami_id remains AAP controlled.
##################################################################################################

demo_ec2_access_method = "ssm"

backup_integration_enabled = false

naming = {
  organization             = "org"
  project                  = "ire"
  project_display_name     = "IRE"
  environment              = "sandbox"
  environment_display_name = "Sandbox"

  region_code = null

  suffix = null
}

# Recovery owns only Recovery-specific name overrides.
resource_name_overrides = {}
