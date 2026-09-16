##################################################################################################
# Generic Platform Service Placement
##################################################################################################

variable "security_groups" {
  description = "Security groups keyed by caller-defined logical name and placed into VPCs using vpc_key."

  type = map(object({
    name        = optional(string)
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

  validation {
    condition = alltrue([
      for security_group in values(var.security_groups) :
      security_group.name == null ? true : length(trimspace(security_group.name)) > 0
    ])

    error_message = "Security group names must be null or non-empty strings."
  }
}

variable "ssm_endpoint_bindings" {
  description = "VPCs that receive the private Systems Manager endpoint plane."

  type = map(object({
    security_group_name        = optional(string)
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

  validation {
    condition = alltrue([
      for binding in values(var.ssm_endpoint_bindings) :
      binding.security_group_name == null ? true : length(trimspace(binding.security_group_name)) > 0
    ])

    error_message = "SSM endpoint security group names must be null or non-empty strings."
  }
}

##################################################################################################
# S3 Gateway Endpoint Placement
##################################################################################################

variable "s3_gateway_endpoint_bindings" {
  description = "VPCs and route-table groups that receive an S3 Gateway VPC endpoint."

  type = map(object({
    name               = optional(string)
    route_table_groups = set(string)
    policy             = optional(string)
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for vpc_key, binding in var.s3_gateway_endpoint_bindings :
      contains(keys(var.network_config.vpcs), vpc_key) &&
      length(binding.route_table_groups) > 0 &&
      alltrue([
        for route_table_group in binding.route_table_groups :
        contains(
          [
            for route_table in values(
              var.network_config.vpcs[vpc_key].route_tables
            ) :
            route_table.group
          ],
          route_table_group
        )
      ])
    ])

    error_message = "Every S3 Gateway endpoint binding must reference an existing VPC and existing route-table groups within that VPC."
  }

  validation {
    condition = alltrue([
      for binding in values(var.s3_gateway_endpoint_bindings) :
      binding.name == null ? true : length(trimspace(binding.name)) > 0
    ])

    error_message = "S3 Gateway endpoint names must be null or non-empty strings."
  }

  validation {
    condition = alltrue([
      for binding in values(var.s3_gateway_endpoint_bindings) :
      binding.policy == null || can(jsondecode(binding.policy))
    ])

    error_message = "S3 Gateway endpoint policies must contain valid JSON when supplied."
  }
}
