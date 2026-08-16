##################################################################################################
# Recovery Compute
##################################################################################################

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = (
    var.demo_ec2_enabled &&
    var.demo_ec2_access_method == "ssh_key"
    ? {
      recovery = {
        public_key = file(var.public_key_path)
      }
    }
    : {}
  )

  tags = local.org_tags
}

module "ec2" {
  source = "../../modules/ec2"

  instances = (
    var.demo_ec2_enabled
    ? {
      for workload_key, workload in var.recovery_workloads :
      workload_key => {
        ami           = local.ec2.ami
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
          var.demo_ec2_access_method == "ssh_key"
          ? module.key_pair.key_names["recovery"]
          : null
        )

        iam_instance_profile = (
          var.demo_ec2_access_method == "ssm"
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
