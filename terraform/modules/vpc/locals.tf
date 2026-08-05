# Locals normalize the module's two supported interfaces into predictable
# internal values.
#
# Keeping this logic here prevents resource files from containing repeated
# conditionals and preserves the repository standard that business logic
# belongs in locals.tf.

locals {

  ##################################################################################################
  # Common tags
  ##################################################################################################

  # Module-level tags provide the base tag set for every resource.
  #
  # Resource-specific tags are merged later and may override these values.
  # The VPC resource itself continues to use vpc_name as its Name tag.
  common_tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags
  )

  ##################################################################################################
  # Operating mode
  ##################################################################################################
  #
  # Legacy mode preserves the existing public_subnets/private_subnets API and
  # its current Terraform resource addresses.
  #
  # Advanced mode uses explicit subnet and route-table objects.
  #
  # variables.tf prevents callers from mixing both modes, while these flags
  # give resource files simple and readable creation conditions.

  legacy_mode = (
    length(var.subnets) == 0 &&
    length(var.route_tables) == 0
  )

  advanced_mode = (
    length(var.subnets) > 0 &&
    length(var.route_tables) > 0
  )

  ##################################################################################################
  # Internet Gateway decisions
  ##################################################################################################

  # Legacy behaviour remains unchanged: supplying public_subnets creates the
  # Internet Gateway and public route table automatically.
  has_public_subnets = (
    local.legacy_mode &&
    length(var.public_subnets) > 0
  )

  # Advanced mode requires the caller to make an explicit Internet Gateway
  # decision. Creating an Internet Gateway does not create routes in advanced
  # mode; routes remain an environment-level responsibility.
  internet_gateway_enabled = (
    local.has_public_subnets ||
    (
      local.advanced_mode &&
      var.create_internet_gateway
    )
  )

  ##################################################################################################
  # Availability Zones
  ##################################################################################################

  # The selected regional AZ list supports portable index-based placement.
  #
  # Example:
  #
  # availability_zone_count = 2
  #
  # local.availability_zones =
  # [
  #   "us-east-1a",
  #   "us-east-1b"
  # ]
  #
  # Advanced subnets may still use an explicit availability_zone or
  # availability_zone_id instead of an index.
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zone_count
  )

  ##################################################################################################
  # Legacy subnet ordering
  ##################################################################################################
  #
  # These locals retain the current deterministic key-to-AZ behaviour for
  # existing callers. They will continue to be consumed only by the legacy
  # aws_subnet.public and aws_subnet.private resources.

  public_subnet_keys = keys(var.public_subnets)

  private_subnet_keys = keys(var.private_subnets)

  ##################################################################################################
  # Advanced route-table normalization
  ##################################################################################################
  #
  # Caller-defined map keys remain the stable Terraform identity.
  #
  # Names and tags are normalized once here so the resource block only needs
  # to consume declarative values.

  advanced_route_tables = {
    for key, route_table in var.route_tables : key => {
      name = coalesce(
        route_table.name,
        "${var.vpc_name}-${key}-rt"
      )

      group = route_table.group

      # The explicit name attribute is authoritative for the Name tag.
      # Caller-supplied resource tags may override module-level tags but do
      # not silently replace the declared resource name.
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
  # Advanced subnet normalization
  ##################################################################################################
  #
  # Each advanced subnet is converted into one consistent internal object,
  # regardless of which Availability Zone selector the caller used.
  #
  # availability_zone_index
  #   Resolves to a regional AZ name from local.availability_zones.
  #
  # availability_zone
  #   Passes the caller-supplied AZ name directly to AWS.
  #
  # availability_zone_id
  #   Remains separate because the aws_subnet resource must not receive both
  #   availability_zone and availability_zone_id.

  advanced_subnets = {
    for key, subnet in var.subnets : key => {
      name = coalesce(
        subnet.name,
        "${var.vpc_name}-${key}"
      )

      cidr_block      = subnet.cidr_block
      group           = subnet.group
      route_table_key = subnet.route_table_key

      # Use the explicit AZ name when supplied. Otherwise resolve an index to
      # a regional AZ name. When availability_zone_id is used, this remains
      # null so Terraform sends only the AZ ID to AWS.
      availability_zone = (
        subnet.availability_zone != null
        ? subnet.availability_zone
        : (
          subnet.availability_zone_index != null
          ? local.availability_zones[subnet.availability_zone_index]
          : null
        )
      )

      availability_zone_id = subnet.availability_zone_id

      map_public_ip_on_launch = subnet.map_public_ip_on_launch

      # Group remains module metadata used for outputs. It is not automatically
      # turned into an enterprise tag because tag standards belong to callers.
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
}