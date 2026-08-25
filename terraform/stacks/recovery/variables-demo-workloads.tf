##################################################################################################
# Recovery Workload Lifecycle
##################################################################################################

variable "demo_ec2_enabled" {
  description = "Controls temporary representative EC2 instances used for IRE recovery and traffic-flow validation."
  type        = bool
  default     = false
}
