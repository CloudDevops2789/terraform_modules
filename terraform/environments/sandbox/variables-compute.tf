##################################################################################################
# Compute Variables
##################################################################################################

variable "public_key_path" {
  description = "Path to an SSH public key. Required only when demo EC2 is enabled with ssh_key access."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !(var.demo_ec2_enabled && var.demo_ec2_access_method == "ssh_key") ||
      (var.public_key_path != null && length(trimspace(var.public_key_path)) > 0)
    )
    error_message = "public_key_path is required when demo_ec2_enabled=true and demo_ec2_access_method=ssh_key."
  }
}

variable "ami_id" {
  description = "Approved EC2 AMI ID used by demonstration instances."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.demo_ec2_enabled ||
      (var.ami_id != null && can(regex("^ami-[0-9a-fA-F]+$", var.ami_id)))
    )
    error_message = "ami_id must be supplied when demo_ec2_enabled=true."
  }
}

#### Tagging Variables #######
