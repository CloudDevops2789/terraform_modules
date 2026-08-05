# Module inputs form the VPC module's public contract.
#
# The module supports two mutually exclusive operating modes:
#
# 1. Legacy mode
#    Uses public_subnets and private_subnets. This preserves all existing
#    consumers and their current Terraform resource addresses.
#
# 2. Advanced topology mode
#    Uses subnets and route_tables. This supports multiple subnet roles,
#    multiple subnets per Availability Zone, and explicit route-table
#    associations without making the module aware of a specific architecture.
#
# Mixing the two modes is rejected because it would create ambiguous
# ownership of subnets and route tables.

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

variable "availability_zone_count" {
  description = "Number of available regional Availability Zones exposed for index-based subnet placement."
  type        = number
  default     = 2

  validation {
    condition = (
      var.availability_zone_count >= 2 &&
      floor(var.availability_zone_count) == var.availability_zone_count
    )

    error_message = "availability_zone_count must be a whole number greater than or equal to two."
  }
}

variable "enable_dns_support" {
  description = "Enables DNS resolution through the Amazon-provided DNS server."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enables DNS hostnames for instances with public IP addresses."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to resources owned by this module."
  type        = map(string)
  default     = {}
}

##################################################################################################
# Legacy subnet interface
##################################################################################################
#
# These inputs remain supported to protect existing callers from migration
# and resource replacement. They continue to create:
#
#   aws_subnet.public
#   aws_subnet.private
#   aws_route_table.public
#   aws_route_table.private
#
# New deployments that need multiple routing domains should use the advanced
# subnets and route_tables inputs instead.

variable "public_subnets" {
  description = "Legacy map of public subnet key to IPv4 CIDR block."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for cidr in values(var.public_subnets) :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every public_subnets value must be a valid IPv4 CIDR block."
  }

  validation {
    condition = (
      length(distinct(values(var.public_subnets))) ==
      length(var.public_subnets)
    )

    error_message = "public_subnets must not contain duplicate CIDR blocks."
  }
}

variable "private_subnets" {
  description = "Legacy map of private subnet key to IPv4 CIDR block."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for cidr in values(var.private_subnets) :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every private_subnets value must be a valid IPv4 CIDR block."
  }

  validation {
    condition = (
      length(distinct(values(var.private_subnets))) ==
      length(var.private_subnets)
    )

    error_message = "private_subnets must not contain duplicate CIDR blocks."
  }
}

##################################################################################################
# Advanced route-table interface
##################################################################################################
#
# Route tables use caller-defined map keys as their stable Terraform identity.
# Subnets reference these keys explicitly rather than relying on inferred
# names, alphabetical order, subnet purpose, or Availability Zone position.
#
# The optional group value is metadata for grouped outputs. It does not change
# routing behaviour and therefore does not introduce architectural assumptions.

variable "route_tables" {
  description = "Advanced route tables keyed by stable caller-defined identifiers."

  type = map(object({
    # Overrides the default Name tag derived from vpc_name and the map key.
    name = optional(string)

    # Logical grouping used by outputs, such as firewall, transit-gateway,
    # application, database, endpoints, or egress.
    group = optional(string, "default")

    # Resource-specific tags override matching module-level tags.
    tags = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for key in keys(var.route_tables) :
      trimspace(key) != ""
    ])

    error_message = "route_tables map keys must not be empty."
  }

  validation {
    condition = alltrue([
      for route_table in values(var.route_tables) :
      route_table.name == null ? true : trimspace(route_table.name) != ""
    ])

    error_message = "A route table name must not be empty when supplied."
  }

  validation {
    condition = alltrue([
      for route_table in values(var.route_tables) :
      trimspace(route_table.group) != ""
    ])

    error_message = "Every route table group must contain a non-empty value."
  }
}

##################################################################################################
# Advanced subnet interface
##################################################################################################
#
# Each subnet explicitly selects:
#
# - its CIDR;
# - its functional group;
# - its route table;
# - its Availability Zone placement.
#
# Exactly one Availability Zone selector is required:
#
# availability_zone_index
#   Provides portable placement such as index 0 and index 1.
#
# availability_zone
#   Provides an explicit account-local AZ name such as us-east-1a.
#
# availability_zone_id
#   Provides consistent physical AZ placement across AWS accounts, such as
#   use1-az1, where account-specific AZ names may differ.
#
# This interface supports multiple subnets in the same Availability Zone and
# does not depend on alphabetical map-key ordering.

variable "subnets" {
  description = "Advanced subnets with explicit Availability Zone placement and route-table association."

  type = map(object({
    # Overrides the default Name tag derived from vpc_name and the map key.
    name = optional(string)

    cidr_block = string

    # Stable key from var.route_tables.
    route_table_key = string

    # Logical role used by grouped outputs. The value has no routing semantics.
    group = optional(string, "default")

    # Exactly one placement selector must be configured.
    availability_zone       = optional(string)
    availability_zone_id    = optional(string)
    availability_zone_index = optional(number)

    # This setting does not make a subnet public by itself. Public reachability
    # also requires an Internet Gateway and an explicit route.
    map_public_ip_on_launch = optional(bool, false)

    # Resource-specific tags override matching module-level tags.
    tags = optional(map(string), {})
  }))

  default = {}

  # Enforce one unambiguous operating mode.
  validation {
    condition = (
      (
        length(var.subnets) == 0 &&
        length(var.route_tables) == 0 &&
        length(var.private_subnets) > 0
      ) ||
      (
        length(var.subnets) > 0 &&
        length(var.route_tables) > 0 &&
        length(var.public_subnets) == 0 &&
        length(var.private_subnets) == 0
      )
    )

    error_message = "Configure either legacy public_subnets/private_subnets or advanced subnets/route_tables. Do not mix both modes. Legacy mode requires at least one private subnet."
  }

  validation {
    condition = alltrue([
      for key in keys(var.subnets) :
      trimspace(key) != ""
    ])

    error_message = "subnets map keys must not be empty."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      can(cidrnetmask(subnet.cidr_block))
    ])

    error_message = "Every advanced subnet cidr_block must be a valid IPv4 CIDR block."
  }

  validation {
    condition = (
      length(distinct([
        for subnet in values(var.subnets) :
        subnet.cidr_block
      ])) == length(var.subnets)
    )

    error_message = "Advanced subnets must not contain duplicate CIDR blocks."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      contains(keys(var.route_tables), subnet.route_table_key)
    ])

    error_message = "Every subnet route_table_key must reference an existing key in route_tables."
  }

  # Counting the configured selectors ensures placement is explicit while
  # preventing conflicting AZ instructions.
  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      (
        (subnet.availability_zone != null ? 1 : 0) +
        (subnet.availability_zone_id != null ? 1 : 0) +
        (subnet.availability_zone_index != null ? 1 : 0)
      ) == 1
    ])

    error_message = "Every advanced subnet must configure exactly one of availability_zone, availability_zone_id, or availability_zone_index."
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
        subnet.availability_zone_index < var.availability_zone_count &&
        floor(subnet.availability_zone_index) == subnet.availability_zone_index
      )
    ])

    error_message = "availability_zone_index must be a whole number from zero through availability_zone_count minus one."
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
      trimspace(subnet.group) != ""
    ])

    error_message = "Every subnet group must contain a non-empty value."
  }
}

##################################################################################################
# Internet Gateway
##################################################################################################
#
# Legacy mode continues to create an Internet Gateway automatically whenever
# public_subnets is non-empty.
#
# Advanced mode requires an explicit decision. Creating the Internet Gateway
# does not create a default route; advanced route ownership remains with the
# consuming environment or a dedicated routing module.

variable "create_internet_gateway" {
  description = "Creates an Internet Gateway explicitly for advanced topology mode. Legacy public subnets continue to enable it automatically."
  type        = bool
  default     = false
}

##################################################################################################
# Legacy Transit Gateway routes
##################################################################################################
#
# These inputs remain part of the legacy contract. Advanced mode exposes route
# table IDs so environments or dedicated routing modules can create arbitrary
# route targets without requiring this VPC module to understand the topology.

variable "public_transit_gateway_routes" {
  description = "Legacy routes added to the shared public route table through a Transit Gateway."

  type = list(object({
    destination_cidr_block = string
    transit_gateway_id     = string
  }))

  default = []

  validation {
    condition = alltrue([
      for route in var.public_transit_gateway_routes :
      can(cidrnetmask(route.destination_cidr_block))
    ])

    error_message = "Every public Transit Gateway route destination must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for route in var.public_transit_gateway_routes :
      can(regex("^tgw-[0-9a-z]+$", route.transit_gateway_id))
    ])

    error_message = "Every public Transit Gateway route must contain a valid Transit Gateway ID."
  }
}

variable "private_transit_gateway_routes" {
  description = "Legacy routes added to the shared private route table through a Transit Gateway."

  type = list(object({
    destination_cidr_block = string
    transit_gateway_id     = string
  }))

  default = []

  validation {
    condition = alltrue([
      for route in var.private_transit_gateway_routes :
      can(cidrnetmask(route.destination_cidr_block))
    ])

    error_message = "Every private Transit Gateway route destination must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for route in var.private_transit_gateway_routes :
      can(regex("^tgw-[0-9a-z]+$", route.transit_gateway_id))
    ])

    error_message = "Every private Transit Gateway route must contain a valid Transit Gateway ID."
  }
}
