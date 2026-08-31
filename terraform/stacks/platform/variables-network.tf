##################################################################################################
# Generic Network Architecture
##################################################################################################

variable "network_config" {
  description = "Topology-agnostic VPC, subnet, route-table, Transit Gateway, connectivity, and inspection configuration."

  type = object({
    account_cidr_block = string

    vpcs = map(object({
      cidr_block = string

      # Optional explicit VPC display name. When omitted the Platform derives
      # the name from the standard environment naming prefix and VPC map key.
      name = optional(string)

      create_internet_gateway = optional(bool, false)

      route_tables = map(object({
        name  = optional(string)
        group = optional(string, "default")
        tags  = optional(map(string), {})
      }))

      subnets = map(object({
        name            = optional(string)
        cidr_block      = string
        group           = optional(string, "default")
        route_table_key = string

        availability_zone       = optional(string)
        availability_zone_id    = optional(string)
        availability_zone_index = optional(number)

        map_public_ip_on_launch = optional(bool, false)
        tags                    = optional(map(string), {})
      }))

      transit_gateway = optional(object({
        enabled                = optional(bool, true)
        route_table_name       = optional(string)
        appliance_mode_support = optional(string, "disable")
      }), {})
    }))

    # Directed connectivity policy.
    #
    # Each entry means:
    #
    #   source VPC route-table groups -> destination VPC
    #
    # Terraform resolves actual CIDRs, route tables, TGW route tables and
    # attachments from the generic VPC map.
    connectivity = optional(map(object({
      source_vpc_key            = string
      destination_vpc_key       = string
      source_route_table_groups = set(string)
    })), {})

    # Optional centralized inspection placement.
    inspection = optional(object({
      vpc_key                      = string
      firewall_subnet_group        = optional(string, "network-firewall")
      transit_gateway_subnet_group = optional(string, "transit-gateway")
    }))
  })

  nullable = false

  validation {
    condition = alltrue(concat(
      [
        can(cidrnetmask(var.network_config.account_cidr_block))
      ],
      flatten([
        for vpc in values(var.network_config.vpcs) : concat(
          [can(cidrnetmask(vpc.cidr_block))],
          [
            for subnet in values(vpc.subnets) :
            can(cidrnetmask(subnet.cidr_block))
          ]
        )
      ])
    ))

    error_message = "All account, Client VPN, VPC, and subnet CIDRs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for edge in values(var.network_config.connectivity) :
      contains(keys(var.network_config.vpcs), edge.source_vpc_key) &&
      contains(keys(var.network_config.vpcs), edge.destination_vpc_key) &&
      edge.source_vpc_key != edge.destination_vpc_key
    ])

    error_message = "Every connectivity entry must reference two different VPC keys that exist in network_config.vpcs."
  }

  validation {
    condition = alltrue([
      for edge in values(var.network_config.connectivity) :
      try(
        length(setintersection(
          edge.source_route_table_groups,
          toset([
            for route_table in values(
              var.network_config.vpcs[edge.source_vpc_key].route_tables
            ) :
            route_table.group
          ])
        )) > 0,
        false
      )
    ])

    error_message = "Every connectivity entry must reference at least one route-table group present in its source VPC."
  }

  validation {
    condition = alltrue([
      for vpc in values(var.network_config.vpcs) :
      !vpc.transit_gateway.enabled ||
      contains(
        [
          for subnet in values(vpc.subnets) :
          subnet.group
        ],
        "transit-gateway"
      )
    ])

    error_message = "Every Transit-Gateway-enabled VPC must provide at least one subnet in the transit-gateway group."
  }

  validation {
    condition = (
      var.network_config.inspection == null ||
      contains(
        keys(var.network_config.vpcs),
        var.network_config.inspection.vpc_key
      )
    )

    error_message = "network_config.inspection.vpc_key must reference a VPC defined in network_config.vpcs."
  }
}

variable "network_inspection_mode" {
  description = "Network inspection mode: firewall or bypass."
  type        = string
  default     = "firewall"

  validation {
    condition = contains(
      ["firewall", "bypass"],
      var.network_inspection_mode
    )

    error_message = "network_inspection_mode must be either firewall or bypass."
  }

  validation {
    condition = (
      var.network_inspection_mode != "firewall" ||
      var.network_config.inspection != null
    )

    error_message = "network_config.inspection must be configured when network_inspection_mode is firewall."
  }
}
