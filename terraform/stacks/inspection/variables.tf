##################################################################################################
# Common Environment
##################################################################################################

variable "aws_region" {
  description = "AWS Region for this environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

##################################################################################################
# Platform Dependency
##################################################################################################
#
# Source:
#   Platform output.inspection_contract
#     -> AAP read_dependency.yml
#     -> runtime_variables.yml
#     -> var.inspection_contract
#
# Platform owns the VPC/TGW topology. Inspection consumes only the identifiers
# required to place Network Firewall and construct endpoint-dependent routing.
##################################################################################################

variable "inspection_contract" {
  description = "Platform-owned topology contract required by the Inspection stack."

  type = object({
    transit_gateway_id = string

    inspection_vpc = object({
      key                           = string
      vpc_id                        = string
      cidr_block                    = string
      transit_gateway_attachment_id = optional(string)

      firewall_subnets_by_az = map(object({
        subnet_id      = string
        cidr_block     = string
        route_table_id = string
      }))

      transit_gateway_subnets_by_az = map(object({
        subnet_id      = string
        cidr_block     = string
        route_table_id = string
      }))
    })

    spoke_vpcs = map(object({
      vpc_id                         = string
      cidr_block                     = string
      transit_gateway_attachment_id  = string
      transit_gateway_route_table_id = string
    }))
  })
}

##################################################################################################
# Persistent Dependency
##################################################################################################
#
# Source:
#   Persistent output.network_firewall_logging_kms_key_arn
#     -> AAP read_dependency.yml
#     -> runtime_variables.yml
#     -> var.persistent_resources
#
# The KMS key remains Persistent-owned. Inspection will consume it only when
# Network Firewall CloudWatch logging is enabled.
##################################################################################################

variable "persistent_resources" {
  description = "Persistent resources consumed by the Inspection stack."

  type = object({
    network_firewall_logging_kms_key_arn = optional(string)
  })

  default = {}
}
