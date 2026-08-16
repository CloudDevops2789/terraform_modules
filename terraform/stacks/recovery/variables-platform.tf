##################################################################################################
# Platform Contract
##################################################################################################

variable "platform_contract" {
  description = "Platform infrastructure values required by Recovery workloads."

  type = object({
    recovery_access_admin_subnet_id = string
    core_recovery_subnet_id         = string
    protected_data_subnet_id        = string

    management_security_group_id = string
    core_security_group_id       = string
    protected_security_group_id  = string

    ssm_instance_profile_name = optional(string)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      !var.demo_ec2_enabled ||
      (
        var.platform_contract != null &&
        try(
          alltrue([
            length(trimspace(var.platform_contract.recovery_access_admin_subnet_id)) > 0,
            length(trimspace(var.platform_contract.core_recovery_subnet_id)) > 0,
            length(trimspace(var.platform_contract.protected_data_subnet_id)) > 0,
            length(trimspace(var.platform_contract.management_security_group_id)) > 0,
            length(trimspace(var.platform_contract.core_security_group_id)) > 0,
            length(trimspace(var.platform_contract.protected_security_group_id)) > 0,
          ]),
          false
        )
      )
    )

    error_message = "platform_contract must provide the required subnet and security-group IDs when Recovery EC2 is enabled."
  }

  validation {
    condition = (
      !(var.demo_ec2_enabled && var.demo_ec2_access_method == "ssm") ||
      try(
        length(trimspace(var.platform_contract.ssm_instance_profile_name)) > 0,
        false
      )
    )

    error_message = "platform_contract.ssm_instance_profile_name is required when Recovery EC2 uses SSM."
  }
}
