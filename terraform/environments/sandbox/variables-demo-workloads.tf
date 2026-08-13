##################################################################################################
# Demonstration Workload Lifecycle
##################################################################################################

variable "demo_ec2_enabled" {
  description = "Controls temporary representative EC2 instances used for IRE connectivity and traffic-flow validation."
  type        = bool
  default     = false
}

variable "demo_ec2_access_method" {
  description = "Interactive access method for demonstration EC2 instances: none, ssm, or ssh_key."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "ssm", "ssh_key"], var.demo_ec2_access_method)
    error_message = "demo_ec2_access_method must be none, ssm, or ssh_key."
  }

  validation {
    condition     = !(var.demo_ec2_enabled && var.demo_ec2_access_method == "ssm") || var.ssm_management_plane_enabled
    error_message = "ssm_management_plane_enabled must be true when demonstration EC2 instances use SSM access."
  }
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
  description = "Existing organization-approved EC2 instance profile used when ssm_instance_profile_mode is external."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !(var.demo_ec2_enabled &&
        var.demo_ec2_access_method == "ssm" &&
      var.ssm_instance_profile_mode == "external") ||
      (var.ssm_instance_profile_name != null &&
      length(trimspace(var.ssm_instance_profile_name)) > 0)
    )
    error_message = "ssm_instance_profile_name is required for SSM access when using an external instance profile."
  }
}
