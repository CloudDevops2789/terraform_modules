##################################################################################################
# VPC Endpoint Module Variables
##################################################################################################

variable "vpc_id" {
  description = "VPC in which the endpoints are created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "interface_endpoints" {
  description = "Interface VPC endpoints to create."

  type = map(object({
    name                = optional(string)
    service_name        = string
    subnet_ids          = set(string)
    security_group_ids  = set(string)
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
    tags                = optional(map(string), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for endpoint in values(var.interface_endpoints) :
      length(trimspace(endpoint.service_name)) > 0 &&
      length(endpoint.subnet_ids) > 0 &&
      length(endpoint.security_group_ids) > 0
    ])
    error_message = "Each interface endpoint requires a service_name, at least one subnet, and at least one security group."
  }

  validation {
    condition = alltrue([
      for endpoint in values(var.interface_endpoints) :
      endpoint.policy == null || can(jsondecode(endpoint.policy))
    ])
    error_message = "Interface endpoint policies must contain valid JSON when supplied."
  }
}

variable "gateway_endpoints" {
  description = "Gateway VPC endpoints to create."

  type = map(object({
    name            = optional(string)
    service_name    = string
    route_table_ids = set(string)
    policy          = optional(string)
    tags            = optional(map(string), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for endpoint in values(var.gateway_endpoints) :
      length(trimspace(endpoint.service_name)) > 0 &&
      length(endpoint.route_table_ids) > 0
    ])
    error_message = "Each gateway endpoint requires a service_name and at least one route table."
  }

  validation {
    condition = alltrue([
      for endpoint in values(var.gateway_endpoints) :
      endpoint.policy == null || can(jsondecode(endpoint.policy))
    ])
    error_message = "Gateway endpoint policies must contain valid JSON when supplied."
  }
}

variable "tags" {
  description = "Common tags applied to VPC endpoints."
  type        = map(string)
  default     = {}
  nullable    = false
}
