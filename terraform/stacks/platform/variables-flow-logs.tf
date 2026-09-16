##################################################################################################
# Network Flow Logging
##################################################################################################
#
# Flow logging is a Platform concern because Platform owns both the VPC
# topology and the Transit Gateway.
#
# The reusable VPC module deliberately remains focused on network topology
# rather than taking dependencies on CloudWatch Logs and IAM.
#
# When enabled:
#
#   - every Platform-owned VPC receives one VPC Flow Log;
#   - the Platform-owned Transit Gateway receives one Transit Gateway Flow Log;
#   - all traffic types are captured;
#   - logs are delivered to CloudWatch Logs;
#   - one shared delivery role is used;
#   - log retention is controlled by the environment.
#
# This capability records network metadata only. It does not alter routing,
# security groups, Network Firewall policy, or packet forwarding.
##################################################################################################

variable "network_flow_logs" {
  description = "Platform network-flow logging configuration for VPCs and the Transit Gateway."

  type = object({
    enabled                      = optional(bool, false)
    vpc_flow_logs_enabled        = optional(bool, true)
    transit_gateway_logs_enabled = optional(bool, true)
    retention_in_days            = optional(number, 30)
  })

  default  = {}
  nullable = false

  validation {
    condition = contains(
      [
        1,
        3,
        5,
        7,
        14,
        30,
        60,
        90,
        120,
        150,
        180,
        365,
        400,
        545,
        731,
        1096,
        1827,
        2192,
        2557,
        2922,
        3288,
        3653
      ],
      var.network_flow_logs.retention_in_days
    )

    error_message = "network_flow_logs.retention_in_days must be a CloudWatch Logs supported retention period."
  }
}
