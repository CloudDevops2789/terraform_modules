################################################################################
# Recovery Compute
#
# Workload definition flow:
#
#   recovery.tfvars
#       -> var.recovery_workloads
#       -> var.platform_contract
#       -> SSH-key resolution in locals.tf
#       -> module.ec2
#
# Platform dependency:
#
#   Platform outputs.tf
#       -> Platform Terraform state
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> var.platform_contract
#
# The Platform contract provides subnet, security-group, and optional SSM
# instance-profile identifiers without hardcoding infrastructure IDs here.
################################################################################

data "aws_key_pair" "recovery_existing" {
  for_each = local.recovery_existing_ssh_key_pairs

  key_name = each.key
}

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = {
    for key_name, config in local.recovery_managed_ssh_key_pairs :
    key_name => {
      public_key = file(config.public_key_path)
    }
  }

  tags = local.org_tags
}

module "ec2" {
  source = "../../modules/ec2"

  instances = (
    var.demo_ec2_enabled
    ? {
      for workload_key, workload in var.recovery_workloads :
      workload_key => {
        name          = workload.server_name
        ami           = workload.ami_id
        instance_type = workload.instance_type

        subnet_id = (
          workload.subnet_key != null
          ? var.platform_contract.subnet_ids[
            workload.vpc_key
            ][
            workload.subnet_key
          ]
          : var.platform_contract.subnet_ids_by_group[
            workload.vpc_key
            ][
            workload.subnet_group
            ][
            workload.subnet_index
          ]
        )

        associate_public_ip_address = (
          workload.associate_public_ip_address
        )

        key_name = (
          contains(
            ["ssh_key", "ssm_with_ssh_fallback"],
            workload.access_method
          )
          ? local.recovery_ssh_key_names[workload.ssh_key_pair_key]
          : null
        )

        iam_instance_profile = (
          contains(
            ["ssm", "ssm_with_ssh_fallback"],
            workload.access_method
          )
          ? try(
            var.platform_contract.ssm_instance_profile_name,
            null
          )
          : null
        )

        vpc_security_group_ids = [
          for security_group_key in sort(
            tolist(workload.security_group_keys)
          ) :
          var.platform_contract.security_group_ids[
            security_group_key
          ]
        ]
      }
    }
    : {}
  )

  tags = local.org_tags
}


################################################################################
# Recovery Backup Policy
#
# Lifecycle ownership:
#   Recovery owns the Backup plan, Backup IAM role, and workload selection.
#
# Persistent owns:
#   Standard Backup vault
#   Logically air-gapped Backup vault
#
# Persistent dependency flow:
#
#   Persistent outputs.tf
#       -> Persistent Terraform state
#       -> playbooks/terraform/tasks/read_dependency.yml
#       -> playbooks/terraform/tasks/runtime_variables.yml
#       -> var.persistent_resources
#       -> Backup plan below
#
# Same-state dependency:
#
#   module.ec2.instance_arns
#       -> module.backup_selection
#
# The explicit EC2 ARN selection intentionally prevents unrelated resources
# from entering the Recovery Backup policy merely because they share tags.
################################################################################

############################################
# Backup Plan
############################################

# Defines how AWS Backup protects the
# recovery environment.
#
# The Backup Plan determines when backups
# are created, how long they are retained,
# and whether recovery points are copied
# to additional Backup Vaults for
# cyber recovery.
# Purpose: Creates the backup schedule, lifecycle settings, and copy actions.
# Change when: Change timing or retention only when RPO and retention requirements change.
module "backup_plan" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-plan"

  name = local.backup.plan_name

  backup_vault_name = var.persistent_resources.standard_backup_vault_name

  rules = {

    daily = {

      schedule = local.backup.plan_rules.daily.schedule

      start_window = local.backup.plan_rules.daily.start_window

      completion_window = local.backup.plan_rules.daily.completion_window

      lifecycle = {

        cold_storage_after = local.backup.plan_rules.daily.cold_storage_after

        delete_after = local.backup.plan_rules.daily.delete_after

      }

      copy_actions = {

        cyber_recovery = {

          destination_vault_arn = var.persistent_resources.air_gapped_backup_vault_arn

          lifecycle = {

            delete_after = local.backup.plan_rules.daily.cyber_recovery_delete_after

          }

        }

      }

    }

  }

  tags = local.org_tags

}

############################################
# Backup IAM Role
############################################

# Creates the IAM Role assumed by AWS Backup
# to perform backup and restore operations.
#
# The role includes the required trust
# relationship and managed IAM policies
# that allow AWS Backup to protect and
# recover supported AWS resources.
#
# Purpose: Creates the IAM role assumed by AWS Backup.
# Change when: Change permissions or trust only when protected resource types or governance requirements change.
module "backup_role" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-role"

  name = local.backup.role_name

  tags = local.org_tags

}

############################################
# Backup Selection
############################################

# Associates AWS resources with the
# Backup Plan.
#
# Only resources included in this
# selection are protected by AWS Backup.
# Workload protection is selected through the configuration-driven
# recovery_workloads backup_enabled attribute.
# Explicit instance ARNs are intentional: Recovery owns both the instances and
# this selection in one state, and exact membership avoids accidentally
# protecting unrelated resources that happen to carry a matching tag.
# Purpose: Associates the selected Sandbox resources with the backup plan.
# Change when: Change protected resource ARNs only when backup scope changes.
module "backup_selection" {

  count = var.backup_integration_enabled ? 1 : 0

  source = "../../modules/backup-selection"

  name = local.backup.selection_name

  backup_plan_id = module.backup_plan[0].id

  iam_role_arn = module.backup_role[0].arn

  resources = [
    for workload_key, instance_arn in module.ec2.instance_arns :
    instance_arn
    if var.recovery_workloads[workload_key].backup_enabled
  ]

  tags = local.org_tags

}
