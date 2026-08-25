##################################################################################################
# Recovery Compute
##################################################################################################

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
