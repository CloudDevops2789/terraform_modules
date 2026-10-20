##################################################################################################
# Sandbox Recovery Stack Configuration
#
# Stable Recovery behavior is Git controlled.
# Only the recovery workload enable/disable lifecycle remains AAP controlled.
# Approved AMIs and access methods are Git-controlled per workload below.
##################################################################################################

backup_integration_enabled = false

naming = {
  organization             = "fv"
  project                  = "ire"
  project_display_name     = "IRE"
  environment              = "sandbox"
  environment_display_name = "Sandbox"

  region_code = null

  suffix = null
}

# Recovery owns only Recovery-specific name overrides.
resource_name_overrides = {}

# Optional SSH exception registry. The map key is the effective AWS EC2 key-pair name.
# access_method = "ssm" or "ssh_key"
# ssh_key_pair_key = "ire-lab-admin"
# Existing organization-managed key pair:
# recovery_ssh_key_pairs = {
#   existing-ire-admin = {
#     source = "existing"
#   }
# }
#
# Terraform-managed public key available inside the AAP project:
# recovery_ssh_key_pairs = {
#   ire-lab-admin = {
#     source          = "managed"
#     public_key_path = "../../environments/sandbox/keys/ire-lab-admin.pub"
#   }
# }

# Representative Recovery workload placement.
# These logical selectors may change without changing Recovery Terraform code.
recovery_workloads = {
  management_windows = {
    server_name       = "A2NIREMGMTWIN001"
    ami_ssm_parameter = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
    access_method     = "ssm"

    vpc_key      = "recovery_access"
    subnet_group = "admin-tools"
    subnet_index = 0

    security_group_keys = [
      "management"
    ]

    backup_enabled = false
  }

  protected_windows = {
    server_name       = "A2NIREPROTWIN001"
    ami_ssm_parameter = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
    access_method     = "ssm"

    vpc_key      = "protected_data"
    subnet_group = "protected-workloads"
    subnet_index = 0

    security_group_keys = [
      "protected"
    ]

    backup_enabled = false
  }

  protected_linux = {
    server_name       = "A2NIREPROTLNX001"
    ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    access_method     = "ssm"

    vpc_key      = "protected_data"
    subnet_group = "protected-workloads"
    subnet_index = 1

    security_group_keys = [
      "protected"
    ]

    backup_enabled = false
  }
}
