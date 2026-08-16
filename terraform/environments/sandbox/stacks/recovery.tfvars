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

# Representative Recovery workload placement.
# These logical selectors may change without changing Recovery Terraform code.
recovery_workloads = {
  management = {
    vpc_key      = "recovery_access"
    subnet_group = "admin-tools"
    subnet_index = 0

    security_group_keys = [
      "management"
    ]

    backup_enabled = false
  }

  core = {
    vpc_key      = "core_recovery"
    subnet_group = "recovery-services"
    subnet_index = 0

    security_group_keys = [
      "core"
    ]

    backup_enabled = true
  }

  protected = {
    vpc_key      = "protected_data"
    subnet_group = "protected-workloads"
    subnet_index = 0

    security_group_keys = [
      "protected"
    ]

    backup_enabled = false
  }
}
