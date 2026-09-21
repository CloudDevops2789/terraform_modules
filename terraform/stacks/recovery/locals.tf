################################################################################
# Recovery Stack Derived Values
#
# Terraform loads all *.tf files in this directory as one root module.
# main.tf does not call locals.tf or variables.tf. References create the
# Terraform dependency graph.
#
# Recovery has three important dependency types:
#
#   Platform state
#       -> var.platform_contract
#       -> workload placement / security / SSM
#
#   Persistent state
#       -> var.persistent_resources
#       -> Backup vault destinations
#
#   Same Recovery state
#       -> module.ec2.instance_arns
#       -> module.backup_selection
################################################################################

locals {
  ##############################################################################
  # Naming
  #
  # Inputs:
  #   var.naming
  #   var.resource_name_overrides
  #   var.aws_region
  #
  # Consumers:
  #   Backup plan, role, and selection names in main.tf
  ##############################################################################

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

  resource_names = {
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
  }

  ##############################################################################
  # Organization Tags
  #
  # Sources:
  #   organization tagging variables declared in variables.tf
  #
  # Consumers:
  #   provider.tf default_tags
  #   module-specific tags in main.tf
  ##############################################################################

  org_tags = var.organization_tags

  ##############################################################################
  # Recovery SSH Key Resolution
  #
  # Inputs:
  #   var.recovery_workloads
  #   var.recovery_ssh_key_pairs
  #   var.demo_ec2_enabled
  #
  # Existing keys are discovered through data.aws_key_pair.recovery_existing.
  # Managed keys are created through module.key_pair.
  #
  # The resulting key-name map is consumed by module.ec2 in main.tf.
  ##############################################################################

  recovery_used_ssh_key_pair_keys = toset([
    for workload in values(var.recovery_workloads) :
    workload.ssh_key_pair_key
    if contains(
      ["ssh_key", "ssm_with_ssh_fallback"],
      workload.access_method
    )
  ])

  recovery_managed_ssh_key_pairs = {
    for key_name, config in var.recovery_ssh_key_pairs :
    key_name => config
    if(
      var.demo_ec2_enabled &&
      config.source == "managed" &&
      contains(local.recovery_used_ssh_key_pair_keys, key_name)
    )
  }

  recovery_existing_ssh_key_pairs = {
    for key_name, config in var.recovery_ssh_key_pairs :
    key_name => config
    if(
      var.demo_ec2_enabled &&
      config.source == "existing" &&
      contains(local.recovery_used_ssh_key_pair_keys, key_name)
    )
  }

  recovery_ssh_key_names = merge(
    {
      for key_name, key_pair in data.aws_key_pair.recovery_existing :
      key_name => key_pair.key_name
    },
    module.key_pair.key_names
  )

  ##############################################################################
  # AWS Backup Policy Defaults
  #
  # Resource names come from the naming section above.
  #
  # Persistent Backup vault identifiers do NOT come from this local block.
  # They enter the Recovery root separately through var.persistent_resources,
  # which is brokered by AAP from Persistent state.
  ##############################################################################

  backup = {
    plan_name      = local.resource_names.backup_plan
    role_name      = local.resource_names.backup_role
    selection_name = local.resource_names.backup_selection

    plan_rules = {
      daily = {
        schedule          = "cron(0 5 ? * * *)"
        start_window      = 60
        completion_window = 180

        cold_storage_after = 30
        delete_after       = 365

        cyber_recovery_delete_after = 365
      }
    }
  }
}
