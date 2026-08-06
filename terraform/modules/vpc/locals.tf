##################################################################################################
# VPC Module Internal Values
##################################################################################################
#
# Variables are the values supplied by the consuming environment.
#
# Locals convert those values into one consistent internal format before the
# AWS resources use them. Keeping this logic here makes the resource files
# easier to read and avoids repeating naming, tagging, and Availability Zone
# calculations.
#
# No AWS resources are created in this file.

locals {

  ##################################################################################################
  # Resource tags
  ##################################################################################################
  #
  # Module-level tags are supplied by the consuming environment. Resource
  # files add their own Name tag after these common tags are applied.

  common_tags = var.tags

  # The VPC has one predictable Name tag.
  vpc_tags = merge(
    local.common_tags,
    {
      Name = var.vpc_name
    }
  )

  ##################################################################################################
  # Availability Zones
  ##################################################################################################
  #
  # AWS returns every currently available Availability Zone in the selected
  # region.
  #
  # A subnet using availability_zone_index = 0 selects the first AZ.
  # A subnet using availability_zone_index = 1 selects the second AZ.
  #
  # Multiple subnets may use the same index. This is what allows several
  # firewall, Transit Gateway, application, or endpoint subnets in one AZ.

  available_availability_zones = data.aws_availability_zones.available.names

  ##################################################################################################
  # Route tables
  ##################################################################################################
  #
  # The caller-defined map key remains the Terraform identity.
  #
  # Example:
  #
  # route_tables = {
  #   firewall-a = {
  #     group = "firewall"
  #   }
  # }
  #
  # creates:
  #
  # aws_route_table.this["firewall-a"]

  route_tables = {
    for key, route_table in var.route_tables : key => {
      name = coalesce(
        route_table.name,
        "${var.vpc_name}-${key}-rt"
      )

      group = route_table.group

      tags = merge(
        local.common_tags,
        route_table.tags,
        {
          Name = coalesce(
            route_table.name,
            "${var.vpc_name}-${key}-rt"
          )
        }
      )
    }
  }

  ##################################################################################################
  # Subnets
  ##################################################################################################
  #
  # Each subnet is converted into one predictable object.
  #
  # A caller may select placement using:
  #
  # - availability_zone;
  # - availability_zone_id;
  # - availability_zone_index.
  #
  # When an index is used, the module resolves it to the corresponding AWS
  # Availability Zone name.
  #
  # try() returns null when an index is larger than the number of available
  # AZs. The subnet resource will contain a lifecycle precondition that turns
  # this into a clear Terraform error rather than allowing AWS to choose an AZ.

  subnets = {
    for key, subnet in var.subnets : key => {
      name = coalesce(
        subnet.name,
        "${var.vpc_name}-${key}"
      )

      cidr_block      = subnet.cidr_block
      group           = subnet.group
      route_table_key = subnet.route_table_key

      availability_zone = (
        subnet.availability_zone != null
        ? subnet.availability_zone
        : (
          subnet.availability_zone_index != null
          ? try(
            local.available_availability_zones[
              subnet.availability_zone_index
            ],
            null
          )
          : null
        )
      )

      # This remains null when the caller selected an AZ name or AZ index.
      # The aws_subnet resource must not receive both an AZ name and an AZ ID.
      availability_zone_id = subnet.availability_zone_id

      availability_zone_index = subnet.availability_zone_index

      map_public_ip_on_launch = subnet.map_public_ip_on_launch

      tags = merge(
        local.common_tags,
        subnet.tags,
        {
          Name = coalesce(
            subnet.name,
            "${var.vpc_name}-${key}"
          )
        }
      )
    }
  }

  ##################################################################################################
  # Resource groups
  ##################################################################################################
  #
  # Groups are caller-defined labels. They make outputs easy to consume
  # without giving the module knowledge of the surrounding architecture.
  #
  # Examples:
  #
  # subnet_ids_by_group["firewall"]
  # subnet_ids_by_group["transit-gateway"]
  # route_table_ids_by_group["application"]

  subnet_groups = toset([
    for subnet in values(local.subnets) :
    subnet.group
  ])

  route_table_groups = toset([
    for route_table in values(local.route_tables) :
    route_table.group
  ])
}
