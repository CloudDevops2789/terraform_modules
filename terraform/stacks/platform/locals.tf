locals {

  ##################################################################################################
  # Portable naming and network inputs
  ##################################################################################################

  region_code_by_region = {
    "us-east-1"  = "use1"
    "us-east-2"  = "use2"
    "us-west-1"  = "usw1"
    "us-west-2"  = "usw2"
    "ap-south-1" = "aps1"
    "ap-south-2" = "aps2"
    "eu-west-1"  = "euw1"
    "eu-west-2"  = "euw2"
  }

  effective_region_code = coalesce(
    var.naming.region_code,
    lookup(
      local.region_code_by_region,
      var.aws_region,
      replace(lower(trimspace(var.aws_region)), "-", "")
    )
  )

  name_prefix = join("-", compact([
    lower(trimspace(var.naming.organization)),
    lower(trimspace(var.naming.project)),
    lower(trimspace(var.naming.environment)),
    local.effective_region_code,
    var.naming.suffix == null ? "" : lower(trimspace(var.naming.suffix)),
  ]))

  derived_network_firewall_name = "${local.name_prefix}-centralized-inspection"

  resource_names = {
    recovery_access_vpc = coalesce(
      var.resource_name_overrides.recovery_access_vpc,
      "${local.name_prefix}-recovery-access-vpc"
    )

    core_recovery_vpc = coalesce(
      var.resource_name_overrides.core_recovery_vpc,
      "${local.name_prefix}-core-recovery-vpc"
    )

    protected_data_vpc = coalesce(
      var.resource_name_overrides.protected_data_vpc,
      "${local.name_prefix}-protected-data-vpc"
    )

    inspection_vpc = coalesce(
      var.resource_name_overrides.inspection_vpc,
      "${local.name_prefix}-inspection-vpc"
    )

    transit_gateway = coalesce(
      var.resource_name_overrides.transit_gateway,
      "${local.name_prefix}-tgw"
    )

    transit_gateway_recovery_access_rt = coalesce(
      var.resource_name_overrides.transit_gateway_recovery_access_rt,
      "${local.name_prefix}-recovery-access-tgw-rt"
    )

    transit_gateway_core_recovery_rt = coalesce(
      var.resource_name_overrides.transit_gateway_core_recovery_rt,
      "${local.name_prefix}-core-recovery-tgw-rt"
    )

    transit_gateway_protected_data_rt = coalesce(
      var.resource_name_overrides.transit_gateway_protected_data_rt,
      "${local.name_prefix}-protected-data-tgw-rt"
    )

    transit_gateway_inspection_rt = coalesce(
      var.resource_name_overrides.transit_gateway_inspection_rt,
      "${local.name_prefix}-inspection-tgw-rt"
    )

    client_vpn = coalesce(
      var.resource_name_overrides.client_vpn,
      "${local.name_prefix}-client-vpn"
    )

    standard_backup_vault = coalesce(
      var.resource_name_overrides.standard_backup_vault,
      "${local.name_prefix}-standard-backup-vault"
    )

    air_gapped_backup_vault = coalesce(
      var.resource_name_overrides.air_gapped_backup_vault,
      "${local.name_prefix}-airgap-backup-vault"
    )

    backup_plan = coalesce(
      var.resource_name_overrides.backup_plan,
      "${local.name_prefix}-backup-plan"
    )

    backup_role = coalesce(
      var.resource_name_overrides.backup_role,
      "${local.name_prefix}-backup-role"
    )

    backup_selection = coalesce(
      var.resource_name_overrides.backup_selection,
      "${local.name_prefix}-backup-selection"
    )

    network_firewall = coalesce(
      var.resource_name_overrides.network_firewall,
      local.derived_network_firewall_name
    )

    network_firewall_policy = coalesce(
      var.resource_name_overrides.network_firewall_policy,
      "${local.name_prefix}-centralized-inspection-policy"
    )

    network_firewall_rule_group = coalesce(
      var.resource_name_overrides.network_firewall_rule_group,
      "${local.name_prefix}-segmentation"
    )

    network_firewall_log_group_prefix = coalesce(
      var.resource_name_overrides.network_firewall_log_group_prefix,
      "/aws/network-firewall/${coalesce(var.resource_name_overrides.network_firewall, local.derived_network_firewall_name)}"
    )
  }

  network_cidrs = merge(
    {
      account    = var.network_config.account_cidr_block
      client_vpn = var.network_config.client_vpn_cidr_block
    },
    {
      for vpc_key, vpc in var.network_config.vpcs :
      vpc_key => vpc.cidr_block
    }
  )

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to the majority of resources created by the environment. Individual
  # modules may merge additional tags (for example Name) on top of these.
  org_required_tags = {
    "fv:it_cost_center"       = var.org_it_cost_center
    "fv:department"           = var.org_department
    "fv:cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "fv:business_criticality" = var.org_business_criticality
    "fv:environment"          = var.org_environment
    "fv:data_classification"  = var.org_data_classification
    "fv:project_name"         = var.org_project_name
    "fv:managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )
}
