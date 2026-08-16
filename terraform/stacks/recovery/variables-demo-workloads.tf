##################################################################################################
# Recovery Workload Lifecycle
##################################################################################################

variable "demo_ec2_enabled" {
  description = "Controls temporary representative EC2 instances used for IRE recovery and traffic-flow validation."
  type        = bool
  default     = false
}

variable "demo_ec2_access_method" {
  description = "Interactive access method for temporary Recovery EC2 instances: none, ssm, or ssh_key."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "ssm", "ssh_key"], var.demo_ec2_access_method)
    error_message = "demo_ec2_access_method must be none, ssm, or ssh_key."
  }
}
