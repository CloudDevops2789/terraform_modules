##################################################################################################
# Platform Management and Administrative Access
##################################################################################################

variable "ssh_key_access_enabled" {
  description = "Controls creation of Platform security-group rules designated for SSH-key administrative access. This is a Git-controlled security posture, not a Recovery runtime control."
  type        = bool
  default     = false
}

variable "ssm_management_plane_enabled" {
  description = "Controls the persistent private Systems Manager management plane."
  type        = bool
  default     = false
}

variable "ssm_instance_profile_mode" {
  description = "Source of the SSM EC2 instance profile: external or terraform."
  type        = string
  default     = "external"

  validation {
    condition     = contains(["external", "terraform"], var.ssm_instance_profile_mode)
    error_message = "ssm_instance_profile_mode must be external or terraform."
  }
}

variable "ssm_instance_profile_name" {
  description = "Existing organization-approved EC2 instance profile used when the Platform management plane uses external instance-profile ownership."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !(
        var.ssm_management_plane_enabled &&
        var.ssm_instance_profile_mode == "external"
      ) ||
      (
        var.ssm_instance_profile_name != null &&
        length(trimspace(var.ssm_instance_profile_name)) > 0
      )
    )

    error_message = "ssm_instance_profile_name is required when the SSM management plane is enabled with external instance-profile ownership."
  }
}

variable "ssh_key_access_rule_names" {
  description = "Security-group rule names that require the explicit Platform ssh_key_access_enabled control."
  type        = set(string)
  default     = []
}
