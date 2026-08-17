##################################################################################################
# Generic Platform Service Placement
##################################################################################################

variable "security_groups" {
  description = "Security groups keyed by caller-defined logical name and placed into VPCs using vpc_key."

  type = map(object({
    description = string
    vpc_key     = string
    tags        = optional(map(string), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for security_group in values(var.security_groups) :
      contains(
        keys(var.network_config.vpcs),
        security_group.vpc_key
      )
    ])

    error_message = "Every security group vpc_key must reference an existing network_config.vpcs entry."
  }
}

variable "client_vpn_network_binding" {
  description = "Topology-independent Client VPN placement and authorization binding."

  type = object({
    vpc_key                = string
    subnet_group           = string
    security_group_keys    = set(string)
    authorization_vpc_keys = set(string)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      (
        var.client_vpn_network_binding != null &&
        try(
          contains(
            keys(var.network_config.vpcs),
            var.client_vpn_network_binding.vpc_key
          ) &&
          alltrue([
            for key in var.client_vpn_network_binding.security_group_keys :
            contains(keys(var.security_groups), key)
          ]) &&
          alltrue([
            for key in var.client_vpn_network_binding.authorization_vpc_keys :
            contains(keys(var.network_config.vpcs), key)
          ]),
          false
        )
      )
    )

    error_message = "When Client VPN is enabled, its VPC, security groups, and authorization VPC keys must reference configured Platform objects."
  }
}

variable "ssm_endpoint_bindings" {
  description = "VPCs that receive the private Systems Manager endpoint plane."

  type = map(object({
    subnet_group               = string
    source_security_group_keys = set(string)
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for vpc_key, binding in var.ssm_endpoint_bindings :
      contains(keys(var.network_config.vpcs), vpc_key) &&
      length(binding.source_security_group_keys) > 0 &&
      alltrue([
        for security_group_key in binding.source_security_group_keys :
        contains(keys(var.security_groups), security_group_key)
      ])
    ])

    error_message = "Every SSM endpoint binding must reference an existing VPC and at least one existing source security group."
  }
}
