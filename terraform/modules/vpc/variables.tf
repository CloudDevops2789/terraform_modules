##################################################################################################
# VPC Module Inputs
##################################################################################################
#
# This module uses one topology model:
#
#   VPC
#     ├── Route tables
#     └── Subnets
#           └── Each subnet explicitly selects one route table
#
# The caller decides:
#
# - how many subnets exist;
# - how many subnets are placed in each Availability Zone;
# - which logical group each subnet belongs to;
# - which route table each subnet uses;
# - whether an Internet Gateway is required.
#
# The module does not assign architectural meaning to group names such as
# firewall, transit-gateway, application, database, endpoints, or management.
# Groups are labels that help consuming environments select related resources.
#
# Routes to Network Firewall endpoints, Transit Gateway, NAT Gateway, VPC
# peering, or other targets remain the responsibility of the consuming
# environment or a dedicated routing module.

##################################################################################################
# VPC
##################################################################################################

variable "vpc_name" {
  description = "Name used to identify the VPC and as the default prefix for resource Name tags."
  type        = string

  validation {
    condition     = trimspace(var.vpc_name) != ""
    error_message = "vpc_name must not be empty."
  }
}

variable "cidr_block" {
  description = "Primary IPv4 CIDR block assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_support" {
  description = "Enables DNS resolution through the Amazon-provided DNS server."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enables DNS hostnames within the VPC."
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Creates an Internet Gateway for the VPC. Routes to the gateway must be created separately."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource owned by this module."
  type        = map(string)
  default     = {}
}

##################################################################################################
# Route Tables
##################################################################################################
#
# Route tables are keyed by caller-defined identifiers.
#
# The map key is the stable Terraform identity used by subnets and outputs.
#
# Example:
#
# route_tables = {
#   firewall-a = {
#     name  = "ire-inspection-firewall-a"
#     group = "firewall"
#   }
#
#   transit-gateway-a = {
#     name  = "ire-inspection-tgw-a"
#     group = "transit-gateway"
#   }
# }
#
# A group may contain one route table, one route table per Availability Zone,
# or any other layout selected by the consuming environment.

variable "route_tables" {
  description = "Route tables keyed by stable caller-defined identifiers."

  type = map(object({
    # Optional display name. When omitted, the module derives a readable name
    # from vpc_name and the route-table map key.
    name = optional(string)

    # Logical grouping used by outputs. The value has no routing behaviour.
    group = optional(string, "default")

    # Resource-specific tags override matching module-level tags.
    tags = optional(map(string), {})
  }))

  validation {
    condition     = length(var.route_tables) > 0
    error_message = "At least one route table must be configured."
  }

  validation {
    condition = alltrue([
      for key in keys(var.route_tables) :
      trimspace(key) != ""
    ])

    error_message = "Route-table map keys must not be empty."
  }

  validation {
    condition = alltrue([
      for route_table in values(var.route_tables) :
      route_table.name == null ? true : trimspace(route_table.name) != ""
    ])

    error_message = "A route-table name must not be empty when supplied."
  }

  validation {
    condition = alltrue([
      for route_table in values(var.route_tables) :
      trimspace(route_table.group) != ""
    ])

    error_message = "Every route-table group must contain a non-empty value."
  }
}

##################################################################################################
# Subnets
##################################################################################################
#
# Every subnet explicitly defines:
#
# - its IPv4 CIDR;
# - its logical group;
# - its route-table key;
# - its Availability Zone placement.
#
# Multiple subnets may use:
#
# - the same Availability Zone;
# - the same group;
# - the same route table.
#
# This allows layouts such as:
#
# us-east-1a
#   firewall-a-1
#   firewall-a-2
#   transit-gateway-a
#   application-a-1
#   application-a-2
#
# Exactly one Availability Zone selector must be configured:
#
# availability_zone_index
#   Portable regional placement. Zero selects the first available AZ, one
#   selects the second, and so on.
#
# availability_zone
#   Explicit account-local AZ name, such as us-east-1a.
#
# availability_zone_id
#   Physical AZ identifier, such as use1-az1. This is useful when aligning
#   Availability Zones consistently across multiple AWS accounts.

variable "subnets" {
  description = "Subnets with explicit Availability Zone placement and route-table association."

  type = map(object({
    # Optional display name. When omitted, the module derives a readable name
    # from vpc_name and the subnet map key.
    name = optional(string)

    cidr_block = string

    # Logical grouping used by outputs. This could be firewall,
    # transit-gateway, application, database, endpoints, or another
    # caller-defined value.
    group = optional(string, "default")

    # Stable key referencing one entry in var.route_tables.
    route_table_key = string

    # Exactly one Availability Zone selector must be configured.
    availability_zone       = optional(string)
    availability_zone_id    = optional(string)
    availability_zone_index = optional(number)

    # This setting does not make a subnet publicly reachable by itself.
    # Public access also requires an Internet Gateway and an explicit route.
    map_public_ip_on_launch = optional(bool, false)

    # Resource-specific tags override matching module-level tags.
    tags = optional(map(string), {})
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be configured."
  }

  validation {
    condition = alltrue([
      for key in keys(var.subnets) :
      trimspace(key) != ""
    ])

    error_message = "Subnet map keys must not be empty."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.name == null ? true : trimspace(subnet.name) != ""
    ])

    error_message = "A subnet name must not be empty when supplied."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      can(cidrnetmask(subnet.cidr_block))
    ])

    error_message = "Every subnet cidr_block must be a valid IPv4 CIDR block."
  }

  validation {
    condition = (
      length(distinct([
        for subnet in values(var.subnets) :
        subnet.cidr_block
      ])) == length(var.subnets)
    )

    error_message = "Subnets must not contain duplicate IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      trimspace(subnet.group) != ""
    ])

    error_message = "Every subnet group must contain a non-empty value."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      trimspace(subnet.route_table_key) != ""
    ])

    error_message = "Every subnet must contain a non-empty route_table_key."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      contains(keys(var.route_tables), subnet.route_table_key)
    ])

    error_message = "Every subnet route_table_key must reference an existing key in route_tables."
  }

  # Count the configured placement selectors. Exactly one must be present,
  # preventing both missing and conflicting Availability Zone instructions.
  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      (
        (subnet.availability_zone != null ? 1 : 0) +
        (subnet.availability_zone_id != null ? 1 : 0) +
        (subnet.availability_zone_index != null ? 1 : 0)
      ) == 1
    ])

    error_message = "Every subnet must configure exactly one of availability_zone, availability_zone_id, or availability_zone_index."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.availability_zone == null
      ? true
      : trimspace(subnet.availability_zone) != ""
    ])

    error_message = "availability_zone must not be empty when supplied."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.availability_zone_id == null
      ? true
      : trimspace(subnet.availability_zone_id) != ""
    ])

    error_message = "availability_zone_id must not be empty when supplied."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.availability_zone_index == null
      ? true
      : (
        subnet.availability_zone_index >= 0 &&
        floor(subnet.availability_zone_index) == subnet.availability_zone_index
      )
    ])

    error_message = "availability_zone_index must be a non-negative whole number."
  }
}
